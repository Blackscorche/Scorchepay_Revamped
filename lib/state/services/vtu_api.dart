import 'package:flutter/foundation.dart';

import '../models/kyc.dart';
import '../models/vtu.dart';

/// The ScorchePay backend, as the app sees it: accounts, identity
/// verification and bills (contract: docs/VTU.md and the backend's API
/// guide). Two implementations: `HttpVtuApi` for the real server and
/// `MockVtuApi`, which runs the whole backend on the device.
///
/// Each instance acts as the holder of one session [token] (see
/// `vtuApiProvider`, which follows the session), so callers never pass
/// one. Features the backend doesn't
/// have yet are off in [features], and their methods throw
/// [UnimplementedError].
abstract class VtuApi {
  /// The session these calls are made with; null while signed out.
  String? get token;

  /// What this backend supports beyond the core API.
  ApiFeatures get features;

  // -------------------------------------------------------------------
  // Accounts (errors: [AuthException])
  // -------------------------------------------------------------------

  /// Sends a sign-up code to a phone number or email. Returns the
  /// verification ID. Calling it again for the same contact resends.
  Future<String> requestSignUpCode(String contact);

  /// Checks the code. Returns a sign-up token for [signUp].
  Future<String> verifySignUpCode(String verificationId, String code);

  /// Throws [AuthException] if [username] is malformed or taken.
  Future<void> checkUsernameAvailable(String username);

  /// Creates the account (KYC tier 0). Returns its session token.
  Future<String> signUp({
    required String signUpToken,
    required String displayName,
    required String username,
    required String pin,
  });

  /// Returns a session token.
  Future<String> login(String username, String pin);

  /// The signed-in user (`GET /v1/me`).
  Future<ApiUser> getMe();

  /// Changes the username and/or display name. Null fields stay as they
  /// are.
  Future<ApiUser> updateMe({String? username, String? displayName});

  /// Sets the profile photo from the image file's bytes. Returns its new
  /// URL.
  Future<String> uploadPhoto(Uint8List photo);

  Future<void> deletePhoto();

  /// Downloads a photo from an [ApiUser.photoUrl].
  Future<Uint8List> loadPhoto(String photoUrl);

  // -------------------------------------------------------------------
  // Identity verification
  // -------------------------------------------------------------------

  /// Starts verification with the KYC provider. Open [KycSession.url]
  /// when there is one, then poll [getMe] while the status is pending.
  Future<KycSession> startIdentityVerification();

  // -------------------------------------------------------------------
  // Passkeys ([ApiFeatures.passkeys]): WebAuthn JSON in and out
  // -------------------------------------------------------------------

  /// `PublicKeyCredentialCreationOptions` for adding a passkey.
  Future<String> startPasskeyRegistration();

  Future<void> finishPasskeyRegistration(String credentialJson);

  /// `PublicKeyCredentialRequestOptions` for logging in.
  Future<String> startPasskeyLogin();

  /// Returns a session token.
  Future<String> finishPasskeyLogin(String credentialJson);

  // -------------------------------------------------------------------
  // Bills (errors: [VtuException])
  // -------------------------------------------------------------------

  Future<Catalog> getCatalog({String country = 'NG'});

  Future<VtuLimits> getLimits();

  /// Looks up the holder of a meter or smartcard. Throws
  /// [VtuErrorCode.customerNotFound].
  Future<CustomerInfo> validateCustomer(
      {required String billerId, required String target, String? optionId});

  /// Locks a quote and returns the order with its invoice, awaiting
  /// payment. Throws [VtuErrorCode.overLimit] when the user's tier caps
  /// don't allow it.
  Future<VtuOrder> createOrder(OrderRequest request);

  /// Prices an unpaid order again (awaiting payment or expired): a fresh
  /// quote and invoice on the same order, whose old invoice can no longer
  /// be paid. With [request], the order's details change too. Throws
  /// [VtuErrorCode.alreadyPaid] once it's paid, or anything [createOrder]
  /// can.
  Future<VtuOrder> requote(String orderId, {OrderRequest? request});

  Future<VtuOrder> getOrder(String orderId);

  /// The user's orders, newest first.
  Future<List<VtuOrder>> listOrders({int limit = 20});

  /// Claims a refund for a [OrderStatus.refundable] order by having the
  /// backend pay [invoice] (BOLT11, for exactly the order's sats).
  Future<VtuOrder> requestRefund(String orderId, {required String invoice});

  /// Development only ([ApiFeatures.simulatePayments]): marks an unpaid
  /// order paid without a Lightning payment.
  Future<void> simulatePayment(String orderId);
}

/// Optional parts of a backend, so the app only offers what it has.
class ApiFeatures {
  /// [passkeys]: the backend supports passkeys. The [passkeys] getter
  /// also checks this platform.
  const ApiFeatures({
    bool passkeys = false,
    this.profilePhotos = false,
    this.simulatePayments = false,
    this.mockScenarios = false,
    this.debugLogin,
    this.debugSignUpCode,
  }) : _apiPasskeys = passkeys;

  final bool _apiPasskeys;

  /// Passkeys can be used: the backend supports them and so does this
  /// platform.
  bool get passkeys => _apiPasskeys && _passkeysPlatformSupported;
  final bool profilePhotos;

  /// [VtuApi.simulatePayment] works (development servers and the mock).
  final bool simulatePayments;

  /// The mock's debug scenario picker applies.
  final bool mockScenarios;

  /// Debug builds: an account to log in with when the username is left
  /// blank.
  final ({String username, String pin})? debugLogin;

  /// Debug builds: the sign-up code that always works.
  final String? debugSignUpCode;

  /// Web uses the browser's WebAuthn API through `web/passkeys_bundle.js`.
  /// Windows is supported by the passkeys package too but isn't set up
  /// here yet.
  static bool get _passkeysPlatformSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

/// `GET /v1/me`.
class ApiUser {
  const ApiUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.kyc,
    this.photoUrl,
  });

  final String id;
  final String username;
  final String displayName;
  final KycInfo kyc;
  final String? photoUrl;

  factory ApiUser.fromJson(Map<String, dynamic> json) => ApiUser(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String? ?? '',
        kyc: json['kyc'] is Map
            ? KycInfo.fromJson(Map<String, dynamic>.from(json['kyc'] as Map))
            : const KycInfo.initial(),
        photoUrl: json['photoUrl'] as String?,
      );
}

/// `POST /v1/kyc/verify`.
class KycSession {
  const KycSession({required this.status, this.url});

  final KycStatus status;

  /// The provider's hosted page to open; null when there's nothing to
  /// open (already verified, or a development server).
  final String? url;

  factory KycSession.fromJson(Map<String, dynamic> json) => KycSession(
        status: KycStatus.fromJson(json['status']),
        url: json['url'] as String?,
      );
}

/// Thrown for account problems: credentials, session, sign-up or profile
/// validation. Its [toString] is the user-facing message.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The backend's error codes (its `error.code`) that the app tells apart.
/// Anything else reads as [unknown]; its message is still shown as is.
enum VtuErrorCode {
  overLimit,
  invalidTarget,
  customerNotFound,
  alreadyPaid,
  billerUnavailable,
  invalidInvoice,
  signedOut,
  notFound,
  network,
  invalid,
  cancelled,
  expired,
  inProgress,
  unknown;

  static VtuErrorCode fromCode(Object? code) =>
      values.where((c) => c.name == code).firstOrNull ?? unknown;
}

/// Thrown for bill problems, and for an unreachable server. Its
/// [toString] is the user-facing message.
class VtuException implements Exception {
  const VtuException(this.code, this.message);

  final VtuErrorCode code;
  final String message;

  @override
  String toString() => message;
}

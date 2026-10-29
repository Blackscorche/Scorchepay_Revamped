import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart'
    show AuthenticateRequestType, RegisterRequestType;

import '../models/kyc.dart';
import '../models/sign_up_draft.dart';
import '../providers/api_providers.dart';
import 'passkey_service.dart';
import 'vtu_api.dart';


/// The signed-in session as the backend sees it.
class Session {
  const Session({required this.token, required this.user});

  final String token;
  final ApiUser user;
}

/// The backend's view of the signed-in user: loaded from the server for
/// the session token ([sessionTokenProvider]), and null while signed out.
/// App state is built on it. Its notifier holds every account action:
/// signing up and in, the profile, passkeys and identity verification.
final backendProvider =
    AsyncNotifierProvider<BackendNotifier, Session?>(BackendNotifier.new);

class BackendNotifier extends AsyncNotifier<Session?> {
  /// Read fresh each time: it follows the session token.
  VtuApi get _api => ref.read(vtuApiProvider);
  SessionTokenNotifier get _session => ref.read(sessionTokenProvider.notifier);

  @override
  Future<Session?> build() async {
    final token = await ref.watch(sessionTokenProvider.future);
    if (token == null) return null;
    final api = ref.watch(vtuApiProvider);
    try {
      return Session(token: token, user: await api.getMe());
    } on AuthException {
      // Token rejected: forget it, which signs out. Any other error (e.g.
      // offline) keeps the token, so a later reload can try again.
      await _session.clear();
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------

  Future<void> login(String username, String pin) async {
    final token = await _api.login(username, pin); // bad PIN throws here
    await _startSession(token);
  }

  /// Logs in with a passkey on this device (the OS shows the biometric
  /// prompt and lets the user pick one if there are several).
  Future<void> loginWithPasskey() async {
    final options = await _api.startPasskeyLogin();
    final assertion = await passkeyCall(() => _passkeys.authenticate(
        AuthenticateRequestType.fromJsonString(options,
            preferImmediatelyAvailableCredentials: false)));
    final token = await _api.finishPasskeyLogin(assertion.toJsonString());
    await _startSession(token);
  }

  Future<void> logout() => _session.clear();

  /// Starts a session with [token] and waits for the user to load.
  Future<void> _startSession(String token) async {
    await _session.start(token);
    try {
      if (await future == null) {
        throw const AuthException("Couldn't sign you in. Please try again.");
      }
    } on AuthException {
      rethrow;
    } catch (_) {
      // The user sees a failed login, so don't keep the token around to
      // sign them in silently on the next launch.
      await _session.clear();
      throw const AuthException("Couldn't reach the server. Please try again.");
    }
  }

  // ---------------------------------------------------------------------
  // Sign-up: verify the contact first, create the account last
  // ---------------------------------------------------------------------

  /// Sends a sign-up code to [contact] (a phone number or email) and
  /// returns the verification ID. Calling it again resends.
  Future<String> requestSignUpCode(String contact) =>
      _api.requestSignUpCode(contact);

  /// Returns a sign-up token proving the contact is verified.
  Future<String> verifySignUpCode(String verificationId, String code) =>
      _api.verifySignUpCode(verificationId, code);

  /// Checks that [username] is valid and free, so the profile step can
  /// report it there instead of at the end of sign-up.
  Future<void> checkUsernameAvailable(String username) =>
      _api.checkUsernameAvailable(username);

  /// Creates the account from a completed [draft] and signs in to it; the
  /// router then leaves the sign-up flow for home.
  ///
  /// Then uploads [SignUpDraft.photo] and, when [ApiFeatures.passkeys] is
  /// on and the user didn't [SignUpDraft.skipPasskey], adds a passkey (the
  /// OS shows the biometric prompt). Both need the
  /// session, and either can fail without failing sign-up: the result says
  /// what didn't work.
  Future<SignUpResult> signUp(SignUpDraft draft) async {
    final signUpToken = draft.signUpToken;
    final pin = draft.pin;
    final username = draft.username;
    if (signUpToken == null || pin == null || username == null) {
      throw StateError('Sign-up is missing a step.');
    }
    // Validation and conflicts (e.g. a taken username) throw here.
    final token = await _api.signUp(
        signUpToken: signUpToken,
        displayName: draft.displayName,
        username: username,
        pin: pin);

    try {
      await _startSession(token);
    } on AuthException {
      // The account exists now, so retrying sign-up would only hit
      // "username taken". Point them at login instead.
      throw const AuthException(
          "Your account was created, but we couldn't sign you in. Please log in.");
    }

    String? photoError;
    if (draft.photo case final photo?) {
      try {
        await _api.uploadPhoto(photo);
        await _reload();
      } catch (error) {
        photoError = error.toString();
      }
    }

    String? passkeyError;
    if (_api.features.passkeys && !draft.skipPasskey) {
      try {
        await registerPasskey();
      } catch (error) {
        passkeyError = error.toString();
      }
    }
    return SignUpResult(photoError: photoError, passkeyError: passkeyError);
  }

  // ---------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------

  /// Changes the username and/or display name. Null fields stay as they
  /// are.
  Future<void> updateUserDetails(
      {String? username, String? displayName}) async {
    _setUser(
        await _api.updateMe(username: username, displayName: displayName));
  }

  /// Sets the profile photo from the image's bytes, or removes it if
  /// [photo] is null.
  Future<void> setProfilePhoto(Uint8List? photo) async {
    if (photo == null) {
      await _api.deletePhoto();
    } else {
      await _api.uploadPhoto(photo);
    }
    await _reload();
  }

  /// Adds a passkey on this device to the signed-in account.
  Future<void> registerPasskey() async {
    final options = await _api.startPasskeyRegistration();
    final credential = await passkeyCall(
        () => _passkeys.register(RegisterRequestType.fromJsonString(options)));
    await _api.finishPasskeyRegistration(credential.toJsonString());
  }

  // ---------------------------------------------------------------------
  // Identity verification
  // ---------------------------------------------------------------------

  static const _kycPollEvery = Duration(seconds: 3);
  static const _kycGiveUpAfter = Duration(minutes: 10);

  /// Verifies the user with the KYC provider to raise their tier (and
  /// limits): starts a session, has [openUrl] open the provider's page
  /// (e.g. in an in-app browser) when there is one, then polls until the
  /// result arrives. Throws [AuthException] if the provider rejected it.
  Future<void> verifyIdentity(
      {required Future<void> Function(Uri url) openUrl}) async {
    final verification = await _api.startIdentityVerification();
    if (verification.url case final url?) await openUrl(Uri.parse(url));

    final giveUpAt = DateTime.now().add(_kycGiveUpAfter);
    var user = await _api.getMe();
    while (user.kyc.status == KycStatus.pending) {
      if (DateTime.now().isAfter(giveUpAt)) {
        throw const AuthException(
            'Verification is still in progress. Check back in a few minutes.');
      }
      await Future.delayed(_kycPollEvery);
      user = await _api.getMe();
    }
    _setUser(user);
    if (user.kyc.status == KycStatus.rejected) {
      throw const AuthException(
          "Your identity couldn't be verified. Check your details and try again.");
    }
  }

  // ---------------------------------------------------------------------

  /// Publishes a fresher copy of the signed-in user.
  void _setUser(ApiUser user) {
    final session = state.valueOrNull;
    if (session != null) {
      state = AsyncData(Session(token: session.token, user: user));
    }
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
  }

  PasskeyAuthenticator get _passkeys => ref.read(passkeyAuthenticatorProvider);
}

/// What [BackendNotifier.signUp]'s optional steps didn't manage.
class SignUpResult {
  const SignUpResult({this.photoError, this.passkeyError});

  final String? photoError;
  final String? passkeyError;
}

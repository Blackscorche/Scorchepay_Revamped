import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;

import '../models/vtu.dart';
import 'vtu_api.dart';

/// [VtuApi] over HTTP, against the ScorchePay backend (`/v1` routes, see
/// the backend's API guide).
///
/// Every failure comes back as `{"error": {"code", "message"}}`, with a
/// message written for the user: account calls throw it as an
/// [AuthException], bill calls as a [VtuException] with the code. A
/// server that can't be reached, or answers `network`, is always a
/// [VtuException] with [VtuErrorCode.network], so a lost connection is
/// never mistaken for a rejected session. A `signedOut` (401) also calls
/// [onSignedOut].
class HttpVtuApi implements VtuApi {
  HttpVtuApi({
    required this.baseUrl,
    required this.token,
    required http.Client client,
    this.onSignedOut,
  }) : _client = client;

  /// e.g. `http://localhost:8080` (no trailing slash needed).
  final String baseUrl;

  @override
  final String? token;

  /// Called when the server says the session is no longer valid.
  final void Function()? onSignedOut;

  /// Shared between instances; its owner closes it.
  final http.Client _client;

  static const _timeout = Duration(seconds: 20);

  // Passkeys aren't on the backend yet. The demo account is the one the
  // backend's development seed creates.
  @override
  ApiFeatures get features => const ApiFeatures(
        passkeys: false,
        profilePhotos: true,
        simulatePayments: kDebugMode,
        debugSignUpCode: '123456',
      );

  // -------------------------------------------------------------------
  // Accounts
  // -------------------------------------------------------------------

  @override
  Future<String> requestSignUpCode(String contact) async {
    final json = await _account('POST', '/v1/auth/signup/code',
        body: {'contact': contact}, auth: false);
    return json['verificationId'] as String;
  }

  @override
  Future<String> verifySignUpCode(String verificationId, String code) async {
    final json = await _account('POST', '/v1/auth/signup/verify',
        body: {'verificationId': verificationId, 'code': code}, auth: false);
    return json['signUpToken'] as String;
  }

  @override
  Future<void> checkUsernameAvailable(String username) async {
    final json = await _account(
        'GET', '/v1/auth/usernames/${Uri.encodeComponent(username.trim())}',
        auth: false);
    if (json['available'] == false) {
      throw const AuthException('That username is taken.');
    }
  }

  @override
  Future<String> signUp({
    required String signUpToken,
    required String displayName,
    required String username,
    required String pin,
  }) async {
    final json = await _account('POST', '/v1/auth/signup',
        body: {
          'signUpToken': signUpToken,
          'displayName': displayName,
          'username': username,
          'pin': pin,
        },
        auth: false);
    return json['token'] as String;
  }

  @override
  Future<String> login(String username, String pin) async {
    final json = await _account('POST', '/v1/auth/login',
        body: {'username': username, 'pin': pin}, auth: false);
    return json['token'] as String;
  }

  @override
  Future<ApiUser> getMe() async =>
      ApiUser.fromJson(await _account('GET', '/v1/me'));

  @override
  Future<ApiUser> updateMe({String? username, String? displayName}) async =>
      ApiUser.fromJson(await _account('PATCH', '/v1/me', body: {
        if (username != null) 'username': username,
        if (displayName != null) 'displayName': displayName,
      }));

  /// The body is the image's raw bytes; the server reads the type from
  /// them.
  @override
  Future<String> uploadPhoto(Uint8List photo) async {
    final json = await _account('PUT', '/v1/me/photo', bytes: photo);
    return json['photoUrl'] as String;
  }

  @override
  Future<void> deletePhoto() async {
    await _account('DELETE', '/v1/me/photo');
  }

  /// A plain GET: photo URLs are public, and change on every upload.
  @override
  Future<Uint8List> loadPhoto(String photoUrl) async {
    final response =
        await _call(() => _client.get(Uri.parse(photoUrl)).timeout(_timeout));
    if (response.statusCode != 200) {
      throw const AuthException('Photo not found.');
    }
    return response.bodyBytes;
  }

  // -------------------------------------------------------------------
  // Identity verification
  // -------------------------------------------------------------------

  @override
  Future<KycSession> startIdentityVerification() async =>
      KycSession.fromJson(await _account('POST', '/v1/kyc/verify'));

  // -------------------------------------------------------------------
  // Passkeys: not on the backend yet ([features] has them off)
  // -------------------------------------------------------------------

  static Never _noPasskeys() => throw UnimplementedError(
      "The backend doesn't support passkeys yet.");

  @override
  Future<String> startPasskeyRegistration() async => _noPasskeys();

  @override
  Future<void> finishPasskeyRegistration(String credentialJson) async =>
      _noPasskeys();

  @override
  Future<String> startPasskeyLogin() async => _noPasskeys();

  @override
  Future<String> finishPasskeyLogin(String credentialJson) async =>
      _noPasskeys();

  // -------------------------------------------------------------------
  // Bills
  // -------------------------------------------------------------------

  @override
  Future<Catalog> getCatalog({String country = 'NG'}) async =>
      Catalog.fromJson(await _bills('GET', '/v1/vtu/catalog',
          query: {'country': country}, auth: false));

  @override
  Future<VtuLimits> getLimits() async =>
      VtuLimits.fromJson(await _bills('GET', '/v1/vtu/limits'));

  @override
  Future<CustomerInfo> validateCustomer(
          {required String billerId,
          required String target,
          String? optionId}) async =>
      CustomerInfo.fromJson(
          await _bills('POST', '/v1/vtu/customers/validate', body: {
        'billerId': billerId,
        'target': target,
        if (optionId != null) 'optionId': optionId,
      }));

  @override
  Future<VtuOrder> createOrder(OrderRequest request) async =>
      VtuOrder.fromJson(
          await _bills('POST', '/v1/vtu/orders', body: _withoutNulls(request)));

  /// No body reprices the order as it was.
  @override
  Future<VtuOrder> requote(String orderId, {OrderRequest? request}) async =>
      VtuOrder.fromJson(await _bills('POST', '/v1/vtu/orders/$orderId/quote',
          body: request == null ? null : _withoutNulls(request)));

  @override
  Future<VtuOrder> getOrder(String orderId) async =>
      VtuOrder.fromJson(await _bills('GET', '/v1/vtu/orders/$orderId'));

  @override
  Future<List<VtuOrder>> listOrders({int limit = 20}) async {
    final json = await _send('GET', '/v1/vtu/orders',
        query: {'limit': '$limit'}, account: false);
    return [
      for (final order in json as List)
        VtuOrder.fromJson(Map<String, dynamic>.from(order as Map))
    ];
  }

  @override
  Future<VtuOrder> requestRefund(String orderId,
          {required String invoice}) async =>
      VtuOrder.fromJson(await _bills('POST', '/v1/vtu/orders/$orderId/refund',
          body: {'invoice': invoice.trim()}));

  /// Only on servers running with `DEV_SIMULATE_PAYMENTS=true`; others
  /// answer `notFound`.
  @override
  Future<void> simulatePayment(String orderId) async {
    await _bills('POST', '/v1/dev/orders/$orderId/simulate-payment',
        auth: false);
  }

  // -------------------------------------------------------------------
  // Transport
  // -------------------------------------------------------------------

  static Map<String, dynamic> _withoutNulls(OrderRequest request) =>
      {...request.toJson()}..removeWhere((_, value) => value == null);

  Future<Map<String, dynamic>> _account(String method, String path,
          {Object? body, Uint8List? bytes, bool auth = true}) async =>
      _asMap(await _send(method, path,
          body: body, bytes: bytes, auth: auth, account: true));

  Future<Map<String, dynamic>> _bills(String method, String path,
          {Object? body, Map<String, String>? query, bool auth = true}) async =>
      _asMap(await _send(method, path,
          body: body, query: query, auth: auth, account: false));

  static Map<String, dynamic> _asMap(Object? json) =>
      json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{};

  /// Sends a request and returns the decoded JSON (null for an empty
  /// body). Throws [AuthException] (when [account]) or [VtuException].
  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Uint8List? bytes,
    Map<String, String>? query,
    bool auth = true,
    required bool account,
  }) async {
    final base = Uri.parse(baseUrl);
    final uri = base.replace(
      path: '${base.path.replaceAll(RegExp(r'/$'), '')}$path',
      queryParameters: query,
    );
    final request = http.Request(method, uri);
    if (auth && token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (bytes != null) {
      request.bodyBytes = bytes;
    } else if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final response = await _call(() async =>
        http.Response.fromStream(await _client.send(request).timeout(_timeout)));
    final text = utf8.decode(response.bodyBytes, allowMalformed: true);
    final json = text.trim().isEmpty ? null : _decode(text);
    if (response.statusCode >= 200 && response.statusCode < 300) return json;

    final error = json is Map && json['error'] is Map
        ? Map<String, dynamic>.from(json['error'] as Map)
        : const <String, dynamic>{};
    final code = VtuErrorCode.fromCode(error['code']);
    final message = error['message'] as String? ??
        'Something went wrong (${response.statusCode}). Please try again.';
    if (code == VtuErrorCode.signedOut || response.statusCode == 401) {
      onSignedOut?.call();
    }
    if (code == VtuErrorCode.network) {
      throw VtuException(VtuErrorCode.network, message);
    }
    if (account) throw AuthException(message);
    throw VtuException(code, message);
  }

  static Object? _decode(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  /// Runs a request, turning a missing connection or timeout into
  /// [VtuErrorCode.network].
  static Future<http.Response> _call(
      Future<http.Response> Function() request) async {
    try {
      return await request();
    } on http.ClientException {
      throw _unreachable;
    } on TimeoutException {
      throw _unreachable;
    }
  }

  static const _unreachable = VtuException(VtuErrorCode.network,
      "Can't reach ScorchePay. Check your connection and try again.");
}

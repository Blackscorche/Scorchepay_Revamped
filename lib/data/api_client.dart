import 'dart:convert';
import 'dart:async';
import 'app_environment.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Live API client. Transport failures are uncertain outcomes, never demo success.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'scp_access_token';
  static const _refreshTokenKey = 'scp_refresh_token';

  String get _baseUrl => AppEnvironment.apiUrl.replaceFirst(RegExp(r'/+$'), '');

  Future<String?> get _accessToken => _storage.read(key: _accessTokenKey);
  Future<String?> get _refreshToken => _storage.read(key: _refreshTokenKey);

  Future<void> _storeTokens(
      {required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<bool> get isSignedIn async => (await _accessToken) != null;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    if (AppEnvironment.isDemo) {
      throw const ApiRequestException('Live API is unavailable in demo mode');
    }
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const ApiUnreachableException();
    } on http.ClientException {
      throw const ApiUnreachableException();
    }
  }

  Map<String, dynamic> _body(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const ApiUnreachableException();
    }
    if (response.statusCode >= 500) throw const ApiUnreachableException();
    if (response.statusCode >= 400) {
      throw ApiRequestException(body['error'] as String? ?? 'Request rejected',
          statusCode: response.statusCode);
    }
    return body;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Retries once after a token refresh if the first attempt 401s — the
  /// access token is short-lived (15 min) by design, so an expired one is
  /// the expected case, not an error to bubble up.
  Future<http.Response> _authedRequest(
      Future<http.Response> Function(Map<String, String> headers)
          request) async {
    var headers = await _authHeaders();
    var response = await _send(() => request(headers));
    if (response.statusCode == 401 && await _refreshToken != null) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        headers = await _authHeaders();
        response = await _send(() => request(headers));
      }
    }
    return response;
  }

  Future<bool>? _refreshInFlight;
  Future<bool> _tryRefresh() => _refreshInFlight ??= _refreshOnce().whenComplete(() => _refreshInFlight = null);
  Future<bool> _refreshOnce() async {
    final refreshToken = await _refreshToken;
    if (refreshToken == null) return false;
    try {
      final response = await _send(() => http.post(
            _uri('/api/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          ));
      if (response.statusCode == 401) {
        await clearSession();
        return false;
      }
      if (response.statusCode != 200) throw const ApiUnreachableException();
      final body = _body(response);
      await _storeTokens(
          accessToken: body['accessToken'], refreshToken: body['refreshToken']);
      return true;
    } on ApiUnreachableException {
      return false;
    }
  }

  Future<Map<String, dynamic>> signup({
    required String username,
    required String displayName,
    required String email,
    required String phone,
    required String pin,
  }) async {
    final response = await _send(() => http.post(
          _uri('/api/auth/signup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'displayName': displayName,
            'email': email,
            'phone': phone,
            'pin': pin,
          }),
        ));
    final body = _body(response);
    if (response.statusCode != 201) {
      throw ApiRequestException(body['error'] as String? ?? 'Sign up failed');
    }
    await _storeTokens(
        accessToken: body['accessToken'], refreshToken: body['refreshToken']);
    return body['user'] as Map<String, dynamic>;
  }

  Future<void> verifyOtp({required String phone, required String code}) async {
    final response = await _authedRequest((headers) => http.post(
          _uri('/api/auth/verify-otp'),
          headers: headers,
          body: jsonEncode({'phone': phone, 'code': code}),
        ));
    if (response.statusCode != 200) {
      final body = _body(response);
      throw ApiRequestException(
          body['error'] as String? ?? 'Verification failed');
    }
  }

  Future<void> login({required String username, required String pin}) async {
    final response = await _send(() => http.post(
          _uri('/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'pin': pin}),
        ));
    final body = _body(response);
    if (response.statusCode != 200) {
      throw ApiRequestException(body['error'] as String? ?? 'Login failed');
    }
    await _storeTokens(
        accessToken: body['accessToken'], refreshToken: body['refreshToken']);
  }

  Future<void> logout() async {
    final refreshToken = await _refreshToken;
    if (refreshToken != null) {
      try {
        await _send(() => http.post(
              _uri('/api/auth/logout'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refreshToken': refreshToken}),
            ));
      } on ApiUnreachableException {
        // Best-effort — still clear the local session below even if the
        // server can't be told to revoke the token right now.
      }
    }
    await clearSession();
  }

  Future<Map<String, dynamic>> sendMoney({
    required String toUsername,
    required String currency,
    required String amount,
    required String pin,
    required String operationId,
    String? note,
  }) async {
    final response = await _authedRequest((headers) => http.post(
          _uri('/api/transfers/send'),
          headers: {...headers, 'Idempotency-Key': operationId},
          body: jsonEncode({
            'toUsername': toUsername,
            'currency': currency,
            'amount': amount,
            'pin': pin,
            if (note != null) 'note': note
          }),
        ));
    return _body(response);
  }

  String newOperationId() => const Uuid().v4();

  Future<Map<String, dynamic>> me() async => _body(await _authedRequest(
      (headers) => http.get(_uri('/api/auth/me'), headers: headers)));

  Future<Map<String, dynamic>> wallet() async => _body(await _authedRequest(
      (headers) => http.get(_uri('/api/wallet/snapshot'), headers: headers)));

  Future<Map<String, dynamic>> resolveRecipient(String username) async =>
      _body(await _authedRequest((headers) => http.get(
          _uri(
              '/api/transfers/recipient?username=${Uri.encodeQueryComponent(username)}'),
          headers: headers)));

  Future<Map<String, dynamic>> operation(String id) async =>
      _body(await _authedRequest((headers) =>
          http.get(_uri('/api/transfers/operations/$id'), headers: headers)));

  Future<void> resendOtp() async {
    _body(await _authedRequest((headers) =>
        http.post(_uri('/api/auth/resend-otp'), headers: headers)));
  }

  Future<Map<String, double>> getBalances() async {
    final response = await _authedRequest(
        (headers) => http.get(_uri('/api/wallet/balance'), headers: headers));
    if (response.statusCode != 200) {
      throw const ApiRequestException('Could not load balances');
    }
    final body = _body(response);
    return body.map((k, v) => MapEntry(k, double.parse(v.toString())));
  }
}

/// A timeout or lost response may happen after the operation committed.
class ApiUnreachableException implements Exception {
  const ApiUnreachableException();
  @override
  String toString() =>
      'Connection interrupted. Check the transaction status before trying again.';
}

class ApiRequestException implements Exception {
  const ApiRequestException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

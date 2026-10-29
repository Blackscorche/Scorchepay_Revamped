import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../app_env_vars.dart';
import '../services/http_vtu_api.dart';
import '../services/mock_vtu_api.dart';
import '../services/secure_storage_keys.dart';
import '../services/vtu_api.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  // useDataProtectionKeyChain can be used with MacOsOptions for testing
  (ref) => const FlutterSecureStorage(),
);

/// The signed-in user's session token, kept in secure storage; null while
/// signed out. Everything that depends on the session follows it:
/// [vtuApiProvider], and through it the backend's view of the user
/// (`backendProvider`) and app state.
final sessionTokenProvider =
    AsyncNotifierProvider<SessionTokenNotifier, String?>(
        SessionTokenNotifier.new);

class SessionTokenNotifier extends AsyncNotifier<String?> {
  FlutterSecureStorage get _storage => ref.read(secureStorageProvider);

  @override
  Future<String?> build() async {
    try {
      return await _storage.read(key: SecureStorageKeys.authToken);
    } catch (_) {
      // Unreadable storage: start signed out.
      return null;
    }
  }

  /// Starts a session with [token] (after logging in or signing up).
  Future<void> start(String token) async {
    await _storage.write(key: SecureStorageKeys.authToken, value: token);
    state = AsyncData(token);
  }

  /// Ends the session: logging out, or a token the server rejected.
  Future<void> clear() async {
    try {
      await _storage.delete(key: SecureStorageKeys.authToken);
    } catch (_) {}
    state = const AsyncData(null);
  }
}

/// The backend as the holder of the current session token: the real
/// server when the build sets `--dart-define=API_BASE_URL=…`, otherwise
/// [MockVtuApi] on the device. Rebuilt when the session or the mock
/// scenario changes, which in turn refreshes everything fetched through it
/// (the user, catalog, limits, orders). A token the server rejects ends
/// the session.
final vtuApiProvider = Provider<VtuApi>((ref) {
  const baseUrl = String.fromEnvironment(AppEnvVars.apiBaseUrl);
  final token = ref.watch(sessionTokenProvider).valueOrNull;
  if (baseUrl.isEmpty) {
    return MockVtuApi(token: token, scenario: ref.watch(mockScenarioProvider));
  }
  return HttpVtuApi(
    baseUrl: baseUrl,
    token: token,
    client: ref.watch(_httpClientProvider),
    onSignedOut: () {
      // Only if that session is still the current one. A late response
      // can arrive after this API was replaced (and its ref disposed).
      try {
        if (ref.read(sessionTokenProvider).valueOrNull == token) {
          ref.read(sessionTokenProvider.notifier).clear();
        }
      } catch (_) {}
    },
  );
});

/// One connection pool for every [HttpVtuApi].
final _httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// What the backend supports beyond the core API.
final apiFeaturesProvider =
    Provider<ApiFeatures>((ref) => ref.watch(vtuApiProvider).features);

/// Whether to offer profile photos: the backend stores them.
final profilePhotosAvailableProvider = Provider<bool>(
    (ref) => ref.watch(apiFeaturesProvider).profilePhotos);

/// Debug builds with [MockVtuApi]: how the mock behaves (see the
/// dashboard's debug menu). Change it through [MockScenarioNotifier.select].
final mockScenarioProvider =
    NotifierProvider<MockScenarioNotifier, MockScenario>(
        MockScenarioNotifier.new);

class MockScenarioNotifier extends Notifier<MockScenario> {
  @override
  MockScenario build() => MockScenario.success;

  void select(MockScenario scenario) => state = scenario;
}

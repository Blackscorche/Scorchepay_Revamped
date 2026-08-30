import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_state.dart';

/// Persists [AppState] to on-device storage as JSON. Any failure to read
/// or parse (first run, corrupted data, a schema change) falls back to
/// [AppState.seed] rather than crashing — this is a local prototype, not
/// a source of truth users can lose real money over.
class LocalStore {
  static const _key = 'scorchepay_app_state_v1';

  Future<AppState> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return AppState.seed();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AppState.fromJson(json);
    } catch (_) {
      return AppState.seed();
    }
  }

  Future<void> save(AppState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(state.toJson()));
    } catch (_) {
      // Best-effort — a failed persist shouldn't crash the app; the next
      // successful save will catch state back up.
    }
  }

  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}

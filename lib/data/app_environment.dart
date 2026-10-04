import 'package:flutter/foundation.dart';

/// Demo is an explicit build mode; a network error can never select it.
class AppEnvironment {
  static const mode =
      String.fromEnvironment('SCORCHEPAY_MODE', defaultValue: 'demo');
  static const apiUrl = String.fromEnvironment('SCORCHEPAY_API_URL');
  static bool get isDemo => mode == 'demo';

  static void validate() {
    if (mode != 'demo' && mode != 'live')
      throw StateError('SCORCHEPAY_MODE must be demo or live');
    if (!isDemo) {
      final uri = Uri.tryParse(apiUrl);
      if (uri == null ||
          !uri.hasAuthority ||
          uri.userInfo.isNotEmpty ||
          uri.hasQuery ||
          uri.hasFragment ||
          (uri.scheme != 'https' && (kReleaseMode || uri.scheme != 'http'))) {
        throw StateError(
            'Live mode requires SCORCHEPAY_API_URL (HTTPS in release builds)');
      }
    }
  }
}

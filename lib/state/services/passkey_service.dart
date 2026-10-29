import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';
import 'vtu_api.dart';

/// Talks to the OS passkey APIs (Credential Manager on Android,
/// AuthenticationServices on iOS/macOS). The backend is the relying
/// party: it issues the WebAuthn JSON these calls take and checks what
/// they return.
final passkeyAuthenticatorProvider =
    Provider<PasskeyAuthenticator>((ref) => PasskeyAuthenticator());

/// Runs a passkey OS call, turning the package's exceptions into an
/// [AuthException] with a user-facing message.
Future<T> passkeyCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on AuthException {
    rethrow;
  } catch (error) {
    throw AuthException(_messageFor(error));
  }
}

String _messageFor(Object error) {
  if (error is PasskeyAuthCancelledException) {
    return 'Passkey request cancelled.';
  }
  if (error is NoCredentialsAvailableException) {
    return 'No ScorchePay passkey on this device. Log in with your PIN.';
  }
  if (error is ExcludeCredentialsCanNotBeRegisteredException) {
    return 'This device already has a passkey for your account.';
  }
  if (error is MissingGoogleSignInException ||
      error is SyncAccountNotAvailableException) {
    return 'Sign in to a Google account on this device to use passkeys.';
  }
  if (error is DomainNotAssociatedException) {
    // App/domain association (assetlinks.json / AASA) is missing or wrong.
    debugPrint('Passkey domain not associated: $error');
    return "Passkeys aren't set up for this app yet.";
  }
  if (error is DeviceNotSupportedException ||
      error is PasskeyUnsupportedException ||
      error is NoCreateOptionException) {
    return "This device can't use passkeys. Make sure a screen lock is set up.";
  }
  debugPrint('Passkey error: $error');
  return "Something went wrong with your passkey. Please try again.";
}

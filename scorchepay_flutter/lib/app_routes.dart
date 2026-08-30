/// Named routes for the screens that take no constructor arguments.
/// Screens that need data passed in (OTP contact, PIN confirmation) are
/// pushed directly with MaterialPageRoute from within the flow instead —
/// see e.g. SignUpScreen -> OtpVerificationScreen, CreatePinScreen ->
/// ConfirmPinScreen.
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';
  static const signup = '/signup';
  static const login = '/login';
  static const home = '/home';
}

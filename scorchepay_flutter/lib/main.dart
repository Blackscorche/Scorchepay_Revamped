import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/shell/main_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ScorchePayApp());
}

class ScorchePayApp extends StatelessWidget {
  const ScorchePayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScorchePay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.welcome: (_) => const WelcomeScreen(),
        AppRoutes.signup: (_) => const SignUpScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.home: (_) => const MainShell(),
      },
    );
  }
}

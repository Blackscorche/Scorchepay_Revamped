import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/buttons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// Landing screen after onboarding — branches into sign up or log in.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  gradient: AppColors.accentGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.flame, size: 34, color: Colors.white),
              ),
              const SizedBox(height: 18),
              const Text('ScorchePay', style: AppText.pageTitle),
              const SizedBox(height: 8),
              const Text(
                'Money, sorted. Fiat and crypto in one place.',
                textAlign: TextAlign.center,
                style: AppText.bodyMuted,
              ),
              const Spacer(flex: 4),
              PrimaryButton(
                label: 'Create an account',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'I already have an account',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
              const SizedBox(height: 18),
              const Text(
                "By continuing you agree to ScorchePay's Terms & Privacy Policy",
                textAlign: TextAlign.center,
                style: AppText.caption,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

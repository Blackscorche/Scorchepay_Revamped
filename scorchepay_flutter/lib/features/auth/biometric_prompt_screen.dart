import 'package:flutter/material.dart';
import '../../app_routes.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/buttons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Final onboarding step — offers to enable biometric login. Either choice
/// proceeds into the app (this is a prototype with no real backend).
class BiometricPromptScreen extends StatelessWidget {
  const BiometricPromptScreen({super.key});

  void _proceed(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

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
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.surface2,
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.faceId, size: 40, color: AppColors.accent),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enable biometric login',
                textAlign: TextAlign.center,
                style: AppText.detailTitle,
              ),
              const SizedBox(height: 10),
              const Text(
                'Use Face ID or your fingerprint to log in faster next time.',
                textAlign: TextAlign.center,
                style: AppText.bodyMuted,
              ),
              const Spacer(flex: 4),
              PrimaryButton(label: 'Enable', onPressed: () => _proceed(context)),
              const SizedBox(height: 10),
              SecondaryButton(label: 'Maybe later', onPressed: () => _proceed(context)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

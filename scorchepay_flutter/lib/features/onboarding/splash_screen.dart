import 'package:flutter/material.dart';
import '../../app_routes.dart';
import '../../core/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// First screen shown on app launch — brand mark, then auto-advances into
/// the onboarding carousel.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  gradient: AppColors.accentGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.flame, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 18),
              const Text(
                'ScorchePay',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text('Your Money OS', style: AppText.caption),
            ],
          ),
        ),
      ),
    );
  }
}

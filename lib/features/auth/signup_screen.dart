import 'package:flutter/material.dart';
import '../../core/widgets/scorch_mascot.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/decorative_rings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';

/// Collects basic details before sending an OTP to verify the contact.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();

  bool get _canContinue =>
      _nameController.text.trim().isNotEmpty &&
      _contactController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _onContinue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(contact: _contactController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: Stack(
        children: [
          const Positioned.fill(child: AuthBackdrop()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  IconCircleButton(
                    icon: AppIcons.chevronLeft,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Align(alignment: Alignment.centerRight, child: ScorchMascot(activity: ScorchActivity.protect, size: 64)),
                  Text('Create your account', style: AppText.pageTitle),
                  const SizedBox(height: 8),
                  Text("Let's get your Money OS set up.",
                      style: AppText.bodyMuted),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      hintText: 'e.g. Scorche Abu',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contactController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Phone number or email',
                      hintText: 'e.g. +234 801 234 5678',
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Continue',
                    onPressed: _canContinue ? _onContinue : null,
                  ),
                  const Spacer(),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account?',
                            style: AppText.bodyMuted),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            );
                          },
                          child: Text(
                            ' Log in',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

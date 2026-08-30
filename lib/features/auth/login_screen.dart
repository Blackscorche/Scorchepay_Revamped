import 'package:flutter/material.dart';
import '../../app_routes.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/decorative_rings.dart';
import '../../core/widgets/pin_dots.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Returning-user login — contact field plus a 4-digit PIN keypad.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _contactController = TextEditingController();
  String _pin = '';

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  void _onKey(String digit) {
    if (_pin.length >= 4) return;
    setState(() => _pin += digit);
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
        }
      });
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _forgotPin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Password reset would be sent to your phone/email.')),
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
                  const SizedBox(height: 24),
                  const Text('Welcome back', style: AppText.pageTitle),
                  const SizedBox(height: 8),
                  const Text('Log in to continue to your money.',
                      style: AppText.bodyMuted),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                        labelText: 'Phone number or email'),
                  ),
                  const SizedBox(height: 28),
                  const Center(
                      child: Text('Enter your PIN', style: AppText.bodyMuted)),
                  const SizedBox(height: 16),
                  Center(child: PinDots(length: 4, filled: _pin.length)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPin,
                      child: const Text(
                        'Forgot PIN?',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                  NumericKeypad(onKey: _onKey, onBackspace: _onBackspace),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

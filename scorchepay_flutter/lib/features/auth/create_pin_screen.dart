import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/pin_dots.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'confirm_pin_screen.dart';

/// First half of PIN setup — captures the desired 4-digit PIN.
class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  String _pin = '';

  void _onKey(String digit) {
    if (_pin.length >= 4) return;
    setState(() => _pin += digit);
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ConfirmPinScreen(originalPin: _pin)),
          );
        }
      });
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
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
              const Text('Create your PIN', style: AppText.pageTitle),
              const SizedBox(height: 8),
              const Text("You'll use this to confirm payments and log in.", style: AppText.bodyMuted),
              const SizedBox(height: 40),
              Center(child: PinDots(length: 4, filled: _pin.length)),
              const SizedBox(height: 40),
              NumericKeypad(onKey: _onKey, onBackspace: _onBackspace),
            ],
          ),
        ),
      ),
    );
  }
}

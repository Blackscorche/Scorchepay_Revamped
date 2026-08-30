import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/otp_boxes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'create_pin_screen.dart';

/// Verifies the contact provided during sign up with a 6-digit code.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.contact});

  final String contact;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _code = '';
  int _secondsLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onCompleted(String code) {
    setState(() => _code = code);
    _goNext();
  }

  void _goNext() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePinScreen()),
    );
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
              const Text('Verify your number', style: AppText.pageTitle),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code we sent to ${widget.contact}',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 32),
              OtpBoxes(
                length: 6,
                onChanged: (v) => setState(() => _code = v),
                onCompleted: _onCompleted,
              ),
              const SizedBox(height: 20),
              Center(
                child: _secondsLeft > 0
                    ? Text('Resend code in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                        style: AppText.caption)
                    : GestureDetector(
                        onTap: _startTimer,
                        child: const Text(
                          'Resend code',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Verify',
                onPressed: _code.length == 6 ? _goNext : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

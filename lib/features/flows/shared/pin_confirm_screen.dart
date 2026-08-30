import 'package:flutter/material.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/pin_dots.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Shared PIN-confirm step used by every money-moving flow in the app —
/// Send, Smart Pay, Escrow funding, Savings contribute/withdraw,
/// Crypto, Cross-border. Demo PIN is fixed at 1234 (local prototype,
/// no real auth server), but the screen still exists and still gates
/// the action, matching the spec's requirement that PIN confirmation is
/// a real step, not skipped.
class PinConfirmScreen extends StatefulWidget {
  const PinConfirmScreen(
      {super.key,
      required this.title,
      required this.subtitle,
      this.demoPin = '1234'});

  final String title;
  final String subtitle;
  final String demoPin;

  @override
  State<PinConfirmScreen> createState() => _PinConfirmScreenState();
}

class _PinConfirmScreenState extends State<PinConfirmScreen> {
  String _entered = '';
  bool _error = false;
  int _attempts = 0;
  bool _lockedOut = false;

  void _onKey(String k) {
    if (_lockedOut || _entered.length >= 4) return;
    setState(() {
      _entered += k;
      _error = false;
    });
    if (_entered.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _check);
    }
  }

  void _check() {
    if (_entered == widget.demoPin) {
      Navigator.of(context).pop(true);
      return;
    }
    _attempts++;
    if (_attempts >= 5) {
      setState(() {
        _lockedOut = true;
        _error = true;
        _entered = '';
      });
      return;
    }
    setState(() {
      _error = true;
      _entered = '';
    });
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() {
      _entered = _entered.substring(0, _entered.length - 1);
      _error = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(AppIcons.chevronLeft,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                    gradient: AppColors.accentGradient, shape: BoxShape.circle),
                child: const Icon(AppIcons.lock, size: 28, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(widget.title,
                  style: AppText.pageTitle.copyWith(fontSize: 20),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(widget.subtitle,
                  style: AppText.bodyMuted, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              PinDots(length: 4, filled: _entered.length),
              const SizedBox(height: 14),
              if (_error)
                Text(
                  _lockedOut
                      ? 'Too many attempts — try again in 30s'
                      : 'Incorrect PIN, try again',
                  style: const TextStyle(
                      color: AppColors.loss,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600),
                ),
              const Spacer(flex: 3),
              NumericKeypad(onKey: _onKey, onBackspace: _onBackspace),
            ],
          ),
        ),
      ),
    );
  }
}

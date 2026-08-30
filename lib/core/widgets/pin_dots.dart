import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../app_icons.dart';

/// Row of filled/outline dots showing PIN entry progress (Create PIN,
/// Confirm PIN, unlock screens).
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.length, required this.filled});

  final int length;
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.accent : Colors.transparent,
            border: Border.all(
                color: isFilled ? AppColors.accent : AppColors.borderStrong,
                width: 1.4),
          ),
        );
      }),
    );
  }
}

/// Numeric keypad used by the PIN screens — 1-9, blank, 0, backspace.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad(
      {super.key, required this.onKey, required this.onBackspace});

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'back'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1.6,
      children: keys.map((k) {
        if (k.isEmpty) return const SizedBox.shrink();
        if (k == 'back') {
          return _KeypadButton(
              child: const Icon(AppIcons.backspace,
                  size: 20, color: AppColors.textSecondary),
              onTap: onBackspace);
        }
        return _KeypadButton(
          child: Text(k,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          onTap: () => onKey(k),
        );
      }).toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(child: child),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/buttons.dart';
import '../../../state/models/demo_account.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'send_amount_screen.dart';

/// Step 2 — the spec's explicit anti-mis-send screen (§8): confirm the
/// resolved account holder's name big and centered before continuing,
/// with an easy way back if it's not who the user meant to pay.
class SendConfirmRecipientScreen extends StatelessWidget {
  const SendConfirmRecipientScreen({super.key, required this.account});

  final DemoAccount account;

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
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(AppIcons.chevronLeft,
                          color: AppColors.textPrimary)),
                ],
              ),
              const Spacer(flex: 2),
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                    color: AppColors.surface2, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(account.initials,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 18),
              const Text('Sending to', style: AppText.bodyMuted),
              const SizedBox(height: 6),
              Text(account.displayName,
                  style: AppText.pageTitle.copyWith(fontSize: 22),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(account.username,
                  style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600)),
              const Spacer(flex: 3),
              Text(
                'Not who you meant to pay? Go back and search again.',
                style: AppText.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'This is correct, continue',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SendAmountScreen(account: account))),
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                  label: 'Go back',
                  onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }
}

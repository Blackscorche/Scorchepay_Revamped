import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/detail_header.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Mock QR scanner — reached from Smart Pay's "pay for anything" grid
/// and anywhere else "Scan QR" is offered as a shortcut.
class ScanQrScreen extends StatelessWidget {
  const ScanQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DetailHeader(
                  icon: AppIcons.qr,
                  title: 'Scan to pay',
                  subtitle: 'Point your camera at a QR code'),
              Expanded(
                child: Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      border:
                          Border.all(color: AppColors.borderStrong, width: 2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.qr,
                            size: 64, color: AppColors.muted),
                        const SizedBox(height: 14),
                        const Text('Camera preview', style: AppText.bodyMuted),
                        const SizedBox(height: 4),
                        const Text('Any ScorchePay, bank or crypto QR code',
                            style: AppText.caption,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
              PrimaryButton(
                label: 'Enter code manually',
                icon: AppIcons.key,
                onPressed: () => showAppModal(
                  context,
                  icon: AppIcons.key,
                  title: 'Enter code manually',
                  message:
                      'Type the recipient\'s username, account or wallet address instead of scanning.',
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/detail_header.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../flows/send/send_recipient_screen.dart';
import 'scan_qr_screen.dart';

/// The bottom-tab-bar QR FAB's destination — show my code to get paid,
/// jump into scanning, or jump straight into Send. A real pushed page
/// rather than the bottom sheet this used to be.
class QuickPayScreen extends StatelessWidget {
  const QuickPayScreen({super.key});

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
                title: 'Quick Pay',
                subtitle:
                    'Show your code to get paid, or scan one to pay someone',
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        alignment: Alignment.center,
                        child: const Icon(AppIcons.qr,
                            size: 120, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      Text('@scorche',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Show this to get paid instantly',
                          style: AppText.caption),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Scan to pay',
                      icon: AppIcons.qr,
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ScanQrScreen())),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Send',
                      icon: AppIcons.send,
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SendRecipientScreen())),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/section_title.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// Smart Pay — pushed full-screen flow reached from the shell's center
/// FAB or the home quick actions. Mirrors renderPay() in the HTML
/// prototype: a single "pay for anything" surface that auto-funds from
/// whatever mix of currencies/crypto makes sense.
class SmartPayScreen extends StatelessWidget {
  const SmartPayScreen({super.key});

  void _info(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            Row(
              children: [
                IconCircleButton(icon: AppIcons.chevronLeft, onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                const Icon(AppIcons.bolt, size: 22, color: AppColors.textPrimary),
                const SizedBox(width: 8),
                const Text('Smart Pay', style: AppText.pageTitle),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Don't think about currencies. Just tap Pay — ScorchePay figures out how to fund it.",
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            GlassHeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Eyebrow("You're paying"),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '₦', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.muted)),
                        TextSpan(text: '24,500', style: AppText.heroNumber.copyWith(fontSize: 42)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('MTN Data · 10GB Monthly Plan', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Auto funding breakdown', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        GestureDetector(
                          onTap: () => _info(context, 'Manually choose NGN, USDT or BTC as the source instead.'),
                          child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 62,
                        child: Container(
                          height: 8,
                          margin: const EdgeInsets.only(right: 1),
                          decoration: const BoxDecoration(
                            color: AppColors.gain,
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 38,
                        child: Container(
                          height: 8,
                          margin: const EdgeInsets.only(left: 1),
                          decoration: const BoxDecoration(
                            color: AppColors.info,
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.gain, borderRadius: BorderRadius.circular(3))),
                          const SizedBox(width: 6),
                          const Text('62% USDT', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.info, borderRadius: BorderRadius.circular(3))),
                          const SizedBox(width: 6),
                          const Text('38% NGN wallet', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            PrimaryButton(
              label: 'Confirm & Pay',
              onPressed: () => _info(context, 'Payment confirmed — ScorchePay converted USDT + NGN automatically.'),
            ),
            const SectionTitle('Pay for anything'),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 6,
                childAspectRatio: 0.82,
                children: [
                  _PayItem(icon: AppIcons.bill, label: 'Airtime'),
                  _PayItem(icon: AppIcons.bill, label: 'Data'),
                  _PayItem(icon: AppIcons.bolt, label: 'Electricity'),
                  _PayItem(icon: AppIcons.monitor, label: 'Cable TV'),
                  _PayItem(icon: AppIcons.package, label: 'Gift Cards'),
                  _PayItem(icon: AppIcons.bag, label: 'Merchant'),
                  _PayItem(icon: AppIcons.shield, label: 'Escrow'),
                  _PayItem(icon: AppIcons.qr, label: 'Scan QR'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Supports NGN · GHS · USD · BTC · ETH · USDT & more',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayItem extends StatelessWidget {
  const _PayItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: 19, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 7),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ],
    );
  }
}

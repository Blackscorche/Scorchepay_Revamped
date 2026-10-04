import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/decorative_rings.dart';
import '../../core/widgets/flag_chip.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class _Institution {
  const _Institution(this.name, this.account, this.routingLabel, this.routing);
  final String name;
  final String account;
  final String routingLabel;
  final String routing;
}

const _institutions = <String, _Institution>{
  'NGN': _Institution('ScorchePay MFB', '8104562311', 'Sort code', '090xxx'),
  'USD': _Institution(
      'ScorchePay (US) N.A.', '2003114487', 'Routing (ABA)', '021000021'),
  'GHS': _Institution(
      'ScorchePay Ghana Ltd', '1140552209', 'Branch code', 'GH-014'),
  'EUR': _Institution('ScorchePay Europe SA', 'DE44 5001 0517 4045 8000 21',
      'SWIFT/BIC', 'SCPYDEFF'),
  'GBP': _Institution('ScorchePay UK Ltd', 'GB29 SCPY 6016 1331 9268 19',
      'Sort code', '60-16-13'),
  'INR': _Institution(
      'ScorchePay India Pvt Ltd', '5021004488213', 'IFSC', 'SCPY0000452'),
  'CNY': _Institution(
      'ScorchePay China Ltd', '6222 0210 0442 8871', 'CNAPS', '308100014452'),
  'SAR': _Institution('ScorchePay Saudi LLC', 'SA44 2000 0001 2345 6789 1234',
      'IBAN', 'SA44 SCPY'),
  'AED': _Institution('ScorchePay UAE FZE', 'AE07 0331 2345 6789 0123 456',
      'IBAN', 'AE07 SCPY'),
};

/// Deposit instructions for a single currency in the unified vault —
/// reached by tapping any fiat balance row on the Wallet tab.
class CurrencyDepositScreen extends StatelessWidget {
  const CurrencyDepositScreen(
      {super.key,
      required this.code,
      required this.flag,
      required this.amount});

  final String code;
  final CountryFlag flag;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final institution = _institutions[code] ?? _institutions['USD']!;
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            Row(
              children: [
                IconCircleButton(
                    icon: AppIcons.chevronLeft,
                    onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                FlagChip(flag: flag, width: 30, height: 21),
                const SizedBox(width: 10),
                Text('Deposit $code',
                    style: AppText.pageTitle.copyWith(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration:
                    BoxDecoration(gradient: AppColors.accentGradient),
                child: Stack(
                  children: [
                    Positioned(
                        top: -30,
                        right: -24,
                        child: RingCircle(
                            size: 100,
                            color: Colors.white.withOpacity(0.16),
                            width: 14)),
                    Positioned(
                        bottom: -34,
                        left: -22,
                        child: RingCircle(
                            size: 76,
                            color: Colors.white.withOpacity(0.10),
                            width: 12)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current balance',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(amount,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text('Your deposit details', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Institution', institution.name),
                  _row('Account number', institution.account),
                  _row('Account name', 'Scorche O.'),
                  _row(institution.routingLabel, institution.routing),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Copy details',
                          icon: AppIcons.copy,
                          onPressed: () => showAppModal(context,
                              icon: AppIcons.copy,
                              title: 'Copied',
                              message:
                                  'Your $code deposit details have been copied to the clipboard.'),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Share',
                          icon: AppIcons.share,
                          onPressed: () => showAppModal(context,
                              icon: AppIcons.share,
                              title: 'Share',
                              message:
                                  'Share your $code deposit details with anyone paying you.'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Funds sent to this account are converted at the live rate and added to your unified vault automatically.',
              style: AppText.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

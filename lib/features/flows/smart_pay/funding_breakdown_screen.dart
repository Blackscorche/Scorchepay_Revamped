import 'package:flutter/material.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../../state/services/smart_pay_engine.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Smart Pay's "how is this funded?" view, promoted to its own screen
/// (spec §7 step 5) — the real [FundingPlan] computed by
/// [SmartPayEngine.planPayment], not decoration. Each leg shows its
/// source currency, the converted native-currency equivalent, and its
/// share of the total.
class FundingBreakdownScreen extends StatelessWidget {
  const FundingBreakdownScreen(
      {super.key, required this.plan, required this.payLabel});

  final FundingPlan plan;
  final String payLabel;

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
              Row(
                children: [
                  IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: Icon(AppIcons.chevronLeft,
                          color: AppColors.textPrimary)),
                  const SizedBox(width: 4),
                  Text('Funding breakdown', style: AppText.pageTitle),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                  'Total: ${plan.nativeAmount.toStringAsFixed(2)} ${plan.nativeCurrency}',
                  style: AppText.bodyMuted),
              const SizedBox(height: 18),
              if (!plan.isSufficient)
                AppCard(
                  color: AppColors.loss.withOpacity(0.12),
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "You're short by ${plan.shortBy.toStringAsFixed(2)} ${plan.nativeCurrency} across every balance you hold — top up your wallet to continue.",
                    style: const TextStyle(
                        color: AppColors.loss,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.4),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  itemCount: plan.legs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final leg = plan.legs[i];
                    return AppCard(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(leg.currency,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary)),
                                  if (leg.isVolatileCrypto) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color:
                                              AppColors.warn.withOpacity(0.14),
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: const Text('Volatile',
                                          style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.warn)),
                                    ),
                                  ],
                                ],
                              ),
                              Text('${plan.pctOf(leg).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            leg.needsConversion
                                ? '${leg.sourceAmount.toStringAsFixed(leg.currency == 'NGN' ? 2 : 6)} ${leg.currency} → ${leg.nativeEquivalent.toStringAsFixed(2)} ${plan.nativeCurrency}'
                                : '${leg.sourceAmount.toStringAsFixed(2)} ${leg.currency}',
                            style: AppText.caption,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              PrimaryButton(
                  label: payLabel,
                  onPressed: plan.isSufficient
                      ? () => Navigator.of(context).pop(true)
                      : null),
            ],
          ),
        ),
      ),
    );
  }
}

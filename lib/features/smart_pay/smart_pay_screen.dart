import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/icon_action_button.dart';
import '../../core/widgets/section_title.dart';
import '../../state/providers/providers.dart';
import '../../state/services/smart_pay_engine.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../bills/airtime_screen.dart';
import '../bills/bill_payment_screen.dart';
import '../bills/data_screen.dart';
import '../bills/gift_card_screen.dart';
import '../flows/escrow/escrow_list_screen.dart';
import '../flows/shared/pin_confirm_screen.dart';
import '../flows/shared/processing_screen.dart';
import '../flows/shared/result_screen.dart';
import '../flows/smart_pay/funding_breakdown_screen.dart';
import '../more/book_detail_screen.dart';
import '../send/scan_qr_screen.dart';

const _demoAmount = 24500.0;
const _demoBiller = 'MTN Data';
const _demoCustomerId = '0803•••4521';

/// Smart Pay — pushed full-screen flow reached from the shell's center
/// FAB or the home quick actions. Mirrors renderPay() in the HTML
/// prototype: a single "pay for anything" surface that auto-funds from
/// whatever mix of currencies/crypto makes sense. The funding split
/// shown is a real [FundingPlan] from [SmartPayEngine], not decoration.
class SmartPayScreen extends ConsumerWidget {
  const SmartPayScreen({super.key});

  Future<void> _confirmAndPay(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(appStateProvider.notifier);
    final plan =
        notifier.planPayment(nativeCurrency: 'NGN', nativeAmount: _demoAmount);

    final proceed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) =>
          FundingBreakdownScreen(plan: plan, payLabel: 'Confirm & Pay'),
    ));
    if (proceed != true || !context.mounted) return;

    final confirmed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => const PinConfirmScreen(
          title: 'Confirm PIN',
          subtitle: 'Enter your PIN to pay ₦24,500 for MTN Data'),
    ));
    if (confirmed != true || !context.mounted) return;

    final result =
        await Navigator.of(context).push<SmartPayResult>(MaterialPageRoute(
      builder: (_) => ProcessingScreen<SmartPayResult>(
        steps: const ['Debiting funding sources…', 'Contacting MTN…'],
        task: () => notifier.payBill(
            biller: _demoBiller,
            customerId: _demoCustomerId,
            amount: _demoAmount,
            currency: 'NGN'),
      ),
    ));
    if (!context.mounted || result == null) return;

    if (result.isSuccess) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResultScreen(
          success: true,
          headline: 'Payment successful',
          lines: [
            const ResultLine('Biller', _demoBiller),
            const ResultLine('Amount', '₦24,500.00'),
            ResultLine('Reference', result.reference ?? '—'),
          ],
          primaryLabel: 'Done',
          onPrimary: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ));
    } else {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResultScreen(
          success: false,
          headline: 'Payment failed',
          detailMessage: result.outcome == SmartPayOutcome.insufficientFunds
              ? result.message
              : '${result.message} — your ₦24,500 has been refunded.',
          lines: const [],
          primaryLabel: 'Retry',
          onPrimary: () => Navigator.of(context).pop(),
          secondaryLabel: 'Cancel',
          onSecondary: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref
        .watch(appStateProvider.notifier)
        .planPayment(nativeCurrency: 'NGN', nativeAmount: _demoAmount);
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
                Icon(AppIcons.bolt,
                    size: 22, color: AppColors.textPrimary),
                const SizedBox(width: 8),
                Text('Smart Pay', style: AppText.pageTitle),
              ],
            ),
            const SizedBox(height: 10),
            Text(
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
                        TextSpan(
                            text: '₦',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted)),
                        TextSpan(
                            text: '24,500',
                            style: AppText.heroNumber.copyWith(fontSize: 42)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('MTN Data · 10GB Monthly Plan',
                      style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _confirmAndPay(context, ref),
                    behavior: HitTestBehavior.opaque,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Auto funding breakdown',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          Text('Change',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (int i = 0; i < plan.legs.length; i++)
                        Expanded(
                          flex: (plan.pctOf(plan.legs[i]) * 10)
                              .round()
                              .clamp(1, 1000),
                          child: Container(
                            height: 8,
                            margin: EdgeInsets.only(
                              right: i == plan.legs.length - 1 ? 0 : 1,
                              left: i == 0 ? 0 : 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.categorical[
                                  i % AppColors.categorical.length],
                              borderRadius: BorderRadius.horizontal(
                                left: i == 0
                                    ? const Radius.circular(20)
                                    : Radius.zero,
                                right: i == plan.legs.length - 1
                                    ? const Radius.circular(20)
                                    : Radius.zero,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      for (int i = 0; i < plan.legs.length; i++)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: AppColors.categorical[
                                        i % AppColors.categorical.length],
                                    borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 6),
                            Text(
                                '${plan.pctOf(plan.legs[i]).toStringAsFixed(0)}% ${plan.legs[i].currency}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500)),
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
              onPressed: () => _confirmAndPay(context, ref),
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
                  IconActionButton(
                    icon: AppIcons.phone,
                    label: 'Airtime',
                    size: 44,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AirtimeScreen())),
                  ),
                  IconActionButton(
                    icon: AppIcons.wifi,
                    label: 'Data',
                    size: 44,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DataScreen())),
                  ),
                  IconActionButton(
                    icon: AppIcons.bolt,
                    label: 'Electricity',
                    size: 44,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const BillPaymentScreen(
                              icon: AppIcons.bolt,
                              title: 'Electricity',
                              subtitle: 'Pay your electricity bill instantly',
                              providers: [
                                'Ikeja Electric',
                                'Eko Electric',
                                'Abuja DisCo',
                                'PHED'
                              ],
                              idLabel: 'Meter number',
                              idHint: 'Enter your meter number',
                            ))),
                  ),
                  IconActionButton(
                    icon: AppIcons.monitor,
                    label: 'Cable TV',
                    size: 44,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const BillPaymentScreen(
                              icon: AppIcons.monitor,
                              title: 'Cable TV',
                              subtitle: 'Renew your cable TV subscription',
                              providers: ['DSTV', 'GOtv', 'Startimes'],
                              idLabel: 'Smart card number',
                              idHint: 'Enter your smart card number',
                              packages: [
                                BillPackage('DSTV Padi', '₦4,400'),
                                BillPackage('DSTV Yanga', '₦6,000'),
                                BillPackage('DSTV Compact', '₦19,800'),
                                BillPackage('GOtv Max', '₦8,500'),
                              ],
                            ))),
                  ),
                  IconActionButton(
                    icon: AppIcons.giftCard,
                    label: 'Gift Cards',
                    size: 44,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const GiftCardScreen())),
                  ),
                  IconActionButton(
                    icon: AppIcons.bag,
                    label: 'Merchant',
                    size: 44,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            const BookDetailScreen(bookId: 'merchants'))),
                  ),
                  IconActionButton(
                    icon: AppIcons.shield,
                    label: 'Escrow',
                    size: 44,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const EscrowListScreen())),
                  ),
                  IconActionButton(
                    icon: AppIcons.qr,
                    label: 'Scan QR',
                    size: 44,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ScanQrScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
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

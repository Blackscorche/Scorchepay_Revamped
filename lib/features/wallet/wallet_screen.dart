import 'package:flutter/material.dart';
import '../../core/widgets/scorch_mascot.dart';

import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/charts/donut_chart.dart';
import '../../core/widgets/flag_chip.dart';
import '../../core/widgets/list_row.dart';
import '../../core/widgets/section_title.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../crypto/coin_search_screen.dart';
import '../crypto/crypto_screen.dart';
import '../crypto/crypto_trade_screen.dart';
import '../more/book_detail_screen.dart';
import 'currency_deposit_screen.dart';

/// Wallet tab — unified fiat balances, portfolio allocation donut and
/// statements. Mirrors renderWallet() in the HTML prototype.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  void _openBook(BuildContext context, String id) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: id)));
  }

  void _openAllocation(BuildContext context, String label) {
    if (label == 'Crypto') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const CryptoScreen()));
      return;
    }
    final code = label.split(' / ').first;
    final match = MockData.balances.where((b) => b.code == code);
    if (match.isNotEmpty) {
      final b = match.first;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CurrencyDepositScreen(
              code: b.code, flag: b.flag, amount: b.amount)));
      return;
    }
    _openBook(context, 'multicurrency');
  }

  Future<void> _searchCoins(BuildContext context) async {
    final coin = await Navigator.of(context).push<CryptoAsset>(
        MaterialPageRoute(builder: (_) => const CoinSearchScreen()));
    if (coin == null || !context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          CryptoTradeScreen(mode: CryptoTradeMode.buy, presetAsset: coin),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
      children: [
        const SizedBox(height: 4),
        Text('Wallet', style: AppText.pageTitle),
        const ScorchCompanion(activity: ScorchActivity.wallet, title: 'Everything in its place', message: 'Explore your balances and choose where your money goes.'),

        const SizedBox(height: 16),
        TextField(
          readOnly: true,
          onTap: () => _searchCoins(context),
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'Search assets',
            prefixIcon:
                Icon(AppIcons.search, size: 18, color: AppColors.muted),
          ),
        ),
        const SectionTitle('Unified money vault', topPad: 22),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              for (final b in MockData.balances)
                _FiatBalanceRow(
                  code: b.code,
                  flag: b.flag,
                  amount: b.amount,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CurrencyDepositScreen(
                          code: b.code, flag: b.flag, amount: b.amount))),
                ),
              AppListRow(
                icon: AppIcons.coins,
                title: 'Crypto assets',
                subtitle: '5 holdings',
                showDivider: false,
                trailing: Text(
                  '\$8,940.20',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: AppColors.textPrimary),
                ),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CryptoScreen())),
              ),
            ],
          ),
        ),
        const SectionTitle('Portfolio allocation'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DonutChart(
                slices: [
                  for (final a in MockData.allocation)
                    DonutSlice(a.label, a.pct, a.color)
                ],
                centerLabel: 'Total',
                centerValue: '\$20.1k',
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final a in MockData.allocation)
                      GestureDetector(
                        onTap: () => _openAllocation(context, a.label),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: a.color,
                                    borderRadius: BorderRadius.circular(3)),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(a.label,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary)),
                              ),
                              Text('${a.pct.toInt()}%',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                              const SizedBox(width: 4),
                              Icon(AppIcons.chevronRight,
                                  size: 12, color: AppColors.muted),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Statements'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              AppListRow(
                icon: AppIcons.receipt,
                title: 'Transaction history',
                subtitle: 'Search, filter & export',
                onTap: () => _openBook(context, 'transactions'),
              ),
              AppListRow(
                icon: AppIcons.download,
                title: 'Download statement',
                subtitle: 'PDF / CSV, last 90 days',
                onTap: () => showAppModal(
                  context,
                  icon: AppIcons.check,
                  title: 'Statement downloaded',
                  message:
                      'Your last 90 days of activity has been saved as a PDF and a CSV.',
                ),
              ),
              AppListRow(
                icon: AppIcons.chartBar,
                title: 'Spending analytics',
                subtitle: 'By category & merchant',
                showDivider: false,
                onTap: () => _openBook(context, 'analytics'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fiat balance row: flag swatch inside a bordered circle, code + "Fiat
/// balance" caption, amount trailing — mirrors the HTML's plain
/// (non-tinted) `.ric` variant used only for these rows.
class _FiatBalanceRow extends StatelessWidget {
  const _FiatBalanceRow(
      {required this.code,
      required this.flag,
      required this.amount,
      required this.onTap});

  final String code;
  final CountryFlag flag;
  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hairline)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.hairline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FlagChip(flag: flag),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(code, style: AppText.body),
                  const SizedBox(height: 2),
                  Text('Fiat balance · tap to deposit',
                      style: AppText.caption),
                ],
              ),
            ),
            Text(amount,
                style: AppText.tabular
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 13.5)),
            const SizedBox(width: 6),
            Icon(AppIcons.chevronRight, size: 14, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

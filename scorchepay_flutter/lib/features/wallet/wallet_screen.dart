import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/charts/donut_chart.dart';
import '../../core/widgets/flag_chip.dart';
import '../../core/widgets/list_row.dart';
import '../../core/widgets/section_title.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../crypto/crypto_screen.dart';
import '../more/book_detail_screen.dart';

/// Wallet tab — unified fiat balances, portfolio allocation donut and
/// statements. Mirrors renderWallet() in the HTML prototype.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  void _openBook(BuildContext context, String id) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: id)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
      children: [
        const SizedBox(height: 4),
        const Text('Wallet', style: AppText.pageTitle),
        const SizedBox(height: 16),
        TextField(
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'Search assets',
            prefixIcon: const Icon(AppIcons.search, size: 18, color: AppColors.muted),
          ),
        ),
        const SectionTitle('Unified money vault', topPad: 22),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              for (final b in MockData.balances) _FiatBalanceRow(code: b.code, flag: b.flag, amount: b.amount),
              AppListRow(
                icon: AppIcons.coins,
                title: 'Crypto assets',
                subtitle: '5 holdings',
                showDivider: false,
                trailing: const Text(
                  '\$8,940.20',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary),
                ),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CryptoScreen())),
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
                slices: [for (final a in MockData.allocation) DonutSlice(a.label, a.pct, a.color)],
                centerLabel: 'Total',
                centerValue: '\$20.1k',
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final a in MockData.allocation)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: a.color, borderRadius: BorderRadius.circular(3)),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(a.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                            ),
                            Text('${a.pct.toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
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
              const AppListRow(
                icon: AppIcons.download,
                title: 'Download statement',
                subtitle: 'PDF / CSV, last 90 days',
                showChevron: false,
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
  const _FiatBalanceRow({required this.code, required this.flag, required this.amount});

  final String code;
  final CountryFlag flag;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
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
                const Text('Fiat balance', style: AppText.caption),
              ],
            ),
          ),
          Text(amount, style: AppText.tabular.copyWith(fontWeight: FontWeight.w700, fontSize: 13.5)),
        ],
      ),
    );
  }
}

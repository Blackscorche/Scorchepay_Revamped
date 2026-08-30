import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/charts/wealth_line_chart.dart';
import '../../core/widgets/list_row.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/token_badge.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../more/book_detail_screen.dart';

/// Crypto tab — portfolio hero, buy/sell/swap/deposit actions, holdings
/// list and transfer shortcuts. Mirrors renderCrypto() in the HTML
/// prototype.
class CryptoScreen extends StatelessWidget {
  const CryptoScreen({super.key});

  void _openBook(BuildContext context, String id) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: id)));
  }

  void _info(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
      children: [
        const SizedBox(height: 4),
        const Text('Crypto', style: AppText.pageTitle),
        const SizedBox(height: 16),
        GlassHeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('Crypto portfolio'),
              const SizedBox(height: 10),
              const Text('\$8,940.20', style: AppText.heroNumber),
              const SizedBox(height: 11),
              const Row(
                children: [
                  Icon(AppIcons.arrowUpRight, size: 13, color: AppColors.gain),
                  SizedBox(width: 5),
                  Text('+3.6% (24h)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.gain)),
                ],
              ),
              const SizedBox(height: 16),
              WealthLineChart(points: MockData.wealthTrend),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: AppIcons.plus,
                label: 'Buy',
                primary: true,
                onTap: () => _info(context, 'Buy flow — pick asset, amount, funding source, confirm.'),
              ),
            ),
            Expanded(
              child: _QuickAction(
                icon: AppIcons.minus,
                label: 'Sell',
                onTap: () => _info(context, 'Sell flow — choose asset & payout currency.'),
              ),
            ),
            Expanded(
              child: _QuickAction(
                icon: AppIcons.repeat,
                label: 'Swap',
                onTap: () => _info(context, 'Swap flow — e.g. ETH → USDT instantly.'),
              ),
            ),
            Expanded(
              child: _QuickAction(
                icon: AppIcons.receive,
                label: 'Deposit',
                onTap: () => _openBook(context, 'receive'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _OutlineButton(
                icon: AppIcons.send,
                label: 'Withdraw',
                onTap: () => _openBook(context, 'send'),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _OutlineButton(
                icon: AppIcons.repeat,
                label: 'Convert',
                onTap: () => _info(context, 'Convert flow — any asset to any asset, incl. fiat.'),
              ),
            ),
          ],
        ),
        const SectionTitle('Holdings'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              for (int i = 0; i < MockData.crypto.length; i++)
                _HoldingRow(asset: MockData.crypto[i], showDivider: i != MockData.crypto.length - 1),
            ],
          ),
        ),
        const SectionTitle('Transfers'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: const Column(
            children: [
              AppListRow(icon: AppIcons.user, title: 'Send by username', subtitle: 'Instant, no network fee', showChevron: false),
              AppListRow(icon: AppIcons.qr, title: 'Send by QR code', showChevron: false),
              AppListRow(icon: AppIcons.link, title: 'Send to wallet address', subtitle: 'Select network first', showChevron: false),
              AppListRow(icon: AppIcons.bell, title: 'Price alerts', subtitle: 'Get notified on target price', showChevron: false, showDivider: false),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap, this.primary = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: primary ? AppColors.accentGradient : null,
                color: primary ? null : AppColors.surface,
                border: primary ? null : Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
                boxShadow: primary
                    ? [BoxShadow(color: AppColors.accent.withOpacity(0.45), blurRadius: 16, offset: const Offset(0, 6))]
                    : null,
              ),
              child: Icon(icon, size: 21, color: primary ? Colors.white : AppColors.textSecondary),
            ),
            const SizedBox(height: 7),
            Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 7),
            Text(label, style: AppText.button.copyWith(color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({required this.asset, this.showDivider = true});

  final CryptoAsset asset;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final changeColor = asset.changePct > 0
        ? AppColors.gain
        : asset.changePct < 0
            ? AppColors.loss
            : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: AppColors.hairline)) : null,
      ),
      child: Row(
        children: [
          TokenBadge(glyph: asset.glyph, color: asset.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: asset.name, style: AppText.body),
                      TextSpan(text: '  ${asset.symbol}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w500, fontSize: 11.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text('${asset.holding} ${asset.symbol}', style: AppText.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${_formatPrice(asset.price)}', style: AppText.tabular.copyWith(fontWeight: FontWeight.w700, fontSize: 13.5)),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (asset.changePct != 0)
                    Icon(asset.changePct > 0 ? AppIcons.arrowUpRight : AppIcons.arrowDownRight, size: 11, color: changeColor),
                  Text('${asset.changePct.abs()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: changeColor)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatPrice(double price) {
  final isWhole = price == price.roundToDouble();
  final s = isWhole ? price.toStringAsFixed(0) : price.toStringAsFixed(2);
  final parts = s.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i != 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  if (parts.length > 1) buf.write('.${parts[1]}');
  return buf.toString();
}

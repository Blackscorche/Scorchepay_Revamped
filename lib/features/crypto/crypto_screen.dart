import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/charts/wealth_line_chart.dart';
import '../../core/widgets/icon_action_button.dart';
import '../../core/widgets/list_row.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/token_badge.dart';
import '../../data/coingecko_service.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../more/book_detail_screen.dart';
import '../send/scan_qr_screen.dart';
import 'coin_search_screen.dart';
import 'crypto_trade_screen.dart';
import 'p2p_sell_screen.dart';
import 'price_alerts_screen.dart';

double parseHolding(String holding) =>
    double.tryParse(holding.replaceAll(',', '')) ?? 0;

/// Crypto tab — portfolio hero, buy/sell/swap/deposit actions, holdings
/// list and transfer shortcuts. Mirrors renderCrypto() in the HTML
/// prototype. Prices are fetched live from CoinGecko on load and fall
/// back to the bundled mock prices if the request fails.
class CryptoScreen extends StatefulWidget {
  const CryptoScreen({super.key});

  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen> {
  List<CryptoAsset> _assets = MockData.crypto;
  bool _live = false;

  @override
  void initState() {
    super.initState();
    _loadLivePrices();
  }

  Future<void> _loadLivePrices() async {
    try {
      final prices = await CoinGeckoService.getPrices();
      if (!mounted) return;
      setState(() {
        _assets = [
          for (final a in MockData.crypto)
            prices.containsKey(a.symbol)
                ? a.copyWith(
                    price: prices[a.symbol]!.price,
                    changePct: prices[a.symbol]!.changePct,
                    logoUrl: prices[a.symbol]!.logoUrl)
                : a,
        ];
        _live = true;
      });
    } catch (_) {
      // Offline or rate-limited — the bundled mock prices already cover it.
    }
  }

  double get _totalValue => _assets.fold<double>(
      0, (sum, a) => sum + parseHolding(a.holding) * a.price);

  double get _weightedChangePct {
    if (_totalValue == 0) return 0;
    final weighted = _assets.fold<double>(
        0, (sum, a) => sum + parseHolding(a.holding) * a.price * a.changePct);
    return weighted / _totalValue;
  }

  void _openBook(BuildContext context, String id) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: id)));
  }

  void _trade(BuildContext context, CryptoTradeMode mode) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => CryptoTradeScreen(mode: mode)));
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
    final changePct = _weightedChangePct;
    final changeColor = changePct >= 0 ? AppColors.gain : AppColors.loss;
    // Scaffold (not just ListView) because this screen is also pushed as
    // a standalone route (Home/Wallet quick actions), not only embedded
    // as a MainShell tab — without it there's no Material ancestor for
    // AppListRow's InkWell when pushed on its own.
    return Scaffold(
      backgroundColor: AppColors.page,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
        children: [
          Row(
            children: [
              const Text('Crypto', style: AppText.pageTitle),
              const Spacer(),
              if (_live)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.gain.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.bolt, size: 10, color: AppColors.gain),
                      SizedBox(width: 3),
                      Text('Live · CoinGecko',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gain)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            readOnly: true,
            onTap: () => _searchCoins(context),
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
            decoration: const InputDecoration(
              hintText: 'Search all coins',
              prefixIcon:
                  Icon(AppIcons.search, size: 18, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 16),
          GlassHeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('Crypto portfolio'),
                const SizedBox(height: 10),
                Text('\$${_formatPrice(_totalValue)}',
                    style: AppText.heroNumber),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Icon(
                        changePct >= 0
                            ? AppIcons.arrowUpRight
                            : AppIcons.arrowDownRight,
                        size: 13,
                        color: changeColor),
                    const SizedBox(width: 5),
                    Text(
                        '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(1)}% (24h)',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: changeColor)),
                  ],
                ),
                const SizedBox(height: 16),
                WealthLineChart(points: MockData.cryptoTrend, height: 92),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: IconActionButton(
                  icon: AppIcons.plus,
                  label: 'Buy',
                  onTap: () => _trade(context, CryptoTradeMode.buy),
                ),
              ),
              Expanded(
                child: IconActionButton(
                  icon: AppIcons.minus,
                  label: 'Sell',
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const P2PSellScreen())),
                ),
              ),
              Expanded(
                child: IconActionButton(
                  icon: AppIcons.repeat,
                  label: 'Swap',
                  onTap: () => _trade(context, CryptoTradeMode.swap),
                ),
              ),
              Expanded(
                child: IconActionButton(
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
                  onTap: () => _trade(context, CryptoTradeMode.convert),
                ),
              ),
            ],
          ),
          const SectionTitle('Holdings'),
          AppCard(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
            child: Column(
              children: [
                for (int i = 0; i < _assets.length; i++)
                  _HoldingRow(
                    asset: _assets[i],
                    showDivider: i != _assets.length - 1,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CryptoTradeScreen(
                            mode: CryptoTradeMode.buy, initialAssetIndex: i))),
                  ),
              ],
            ),
          ),
          const SectionTitle('Transfers'),
          AppCard(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
            child: Column(
              children: [
                AppListRow(
                    icon: AppIcons.user,
                    title: 'Send by username',
                    subtitle: 'Instant, no network fee',
                    onTap: () => _openBook(context, 'send')),
                AppListRow(
                    icon: AppIcons.qr,
                    title: 'Send by QR code',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ScanQrScreen()))),
                AppListRow(
                    icon: AppIcons.link,
                    title: 'Send to wallet address',
                    subtitle: 'Select network first',
                    onTap: () => _openBook(context, 'send')),
                AppListRow(
                    icon: AppIcons.bell,
                    title: 'Price alerts',
                    subtitle: 'Get notified on target price',
                    showDivider: false,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const PriceAlertsScreen()))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton(
      {required this.icon, required this.label, required this.onTap});

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
            Text(label,
                style: AppText.button.copyWith(color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow(
      {required this.asset, this.showDivider = true, required this.onTap});

  final CryptoAsset asset;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final changeColor = asset.changePct > 0
        ? AppColors.gain
        : asset.changePct < 0
            ? AppColors.loss
            : AppColors.muted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.hairline))
              : null,
        ),
        child: Row(
          children: [
            TokenBadge(
                glyph: asset.glyph, color: asset.color, logoUrl: asset.logoUrl),
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
                        TextSpan(
                            text: '  ${asset.symbol}',
                            style: const TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w500,
                                fontSize: 11.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('${asset.holding} ${asset.symbol}',
                      style: AppText.caption),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${_formatPrice(asset.price)}',
                    style: AppText.tabular
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (asset.changePct != 0)
                      Icon(
                          asset.changePct > 0
                              ? AppIcons.arrowUpRight
                              : AppIcons.arrowDownRight,
                          size: 11,
                          color: changeColor),
                    Text('${asset.changePct.abs()}%',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: changeColor)),
                  ],
                ),
              ],
            ),
          ],
        ),
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

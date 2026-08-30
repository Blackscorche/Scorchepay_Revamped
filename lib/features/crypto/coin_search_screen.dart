import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/detail_header.dart';
import '../../core/widgets/token_badge.dart';
import '../../data/coingecko_service.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Browse or search the full CoinGecko coin universe (top 100 by market
/// cap) with live prices — not just the handful the user holds. Popping
/// with a [CryptoAsset] lets the caller (Buy/Swap, P2P Sell) drop
/// straight into a trade for whichever coin was picked.
class CoinSearchScreen extends StatefulWidget {
  const CoinSearchScreen({super.key});

  @override
  State<CoinSearchScreen> createState() => _CoinSearchScreenState();
}

class _CoinSearchScreenState extends State<CoinSearchScreen> {
  List<CryptoAsset> _coins = const [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final coins = await CoinGeckoService.getMarket(perPage: 100);
      if (!mounted) return;
      setState(() {
        _coins = coins;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't load coins — check your connection and try again.";
        _loading = false;
      });
    }
  }

  List<CryptoAsset> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _coins;
    return _coins
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.symbol.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: DetailHeader(
                  icon: AppIcons.coins,
                  title: 'All coins',
                  subtitle:
                      'Live prices from CoinGecko · top 100 by market cap'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Search by name or symbol',
                  prefixIcon: const Icon(AppIcons.search,
                      size: 18, color: AppColors.muted),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accent))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(_error!,
                                textAlign: TextAlign.center,
                                style: AppText.bodyMuted),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                          itemCount: results.length,
                          itemBuilder: (context, i) => _CoinRow(
                              asset: results[i],
                              onTap: () =>
                                  Navigator.of(context).pop(results[i])),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinRow extends StatelessWidget {
  const _CoinRow({required this.asset, required this.onTap});

  final CryptoAsset asset;
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            TokenBadge(
                glyph: asset.glyph,
                color: asset.color,
                size: 34,
                logoUrl: asset.logoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: asset.name, style: AppText.body),
                  TextSpan(
                      text: '  ${asset.symbol}',
                      style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                          fontSize: 11.5)),
                ]),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                    '\$${asset.price.toStringAsFixed(asset.price < 1 ? 4 : 2)}',
                    style: AppText.tabular
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                    '${asset.changePct >= 0 ? '+' : ''}${asset.changePct.toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: changeColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

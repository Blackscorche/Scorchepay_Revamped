import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/choice_chip.dart';
import '../../core/widgets/decorative_rings.dart';
import '../../core/widgets/detail_header.dart';
import '../../core/widgets/token_badge.dart';
import '../../data/coingecko_service.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../state/providers/app_state.dart';
import '../../state/providers/providers.dart';
import '../../state/services/simulated_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../flows/shared/pin_confirm_screen.dart';
import '../flows/shared/processing_screen.dart';
import '../flows/shared/result_screen.dart';
import 'coin_search_screen.dart';

enum CryptoTradeMode { buy, swap, convert }

const _feeRate = 0.005;

/// One screen driving Buy, Swap and Convert — all three are the same
/// shape (pick asset(s), enter an amount, pick a source/target, confirm)
/// so this replaces what would otherwise be three near-identical
/// screens. Convert reuses Swap's from/to layout since a mock "any asset
/// to any asset including fiat" conversion has no meaningful UI
/// difference from a swap. Sell has its own P2P flow — see
/// [P2PSellScreen] — since selling to other users, not to the app, is a
/// genuinely different shape of screen.
///
/// Prices are real (live from CoinGecko when reachable), balances are
/// real (debited/credited on the real [AppState] ledger) — only the
/// trade *execution* itself is simulated, since actually routing an
/// order to an exchange means real trading fees, custody of user funds,
/// and licensing (Nigeria's SEC has VASP rules for this) that a demo
/// build shouldn't pretend to have. The badge under the header says so
/// plainly rather than quietly faking it.
class CryptoTradeScreen extends ConsumerStatefulWidget {
  const CryptoTradeScreen(
      {super.key,
      required this.mode,
      this.initialAssetIndex = 0,
      this.presetAsset});

  final CryptoTradeMode mode;
  final int initialAssetIndex;

  /// A coin picked from [CoinSearchScreen] that isn't necessarily one of
  /// the user's held assets — injected at the front of the asset list.
  final CryptoAsset? presetAsset;

  @override
  ConsumerState<CryptoTradeScreen> createState() => _CryptoTradeScreenState();
}

class _CryptoTradeScreenState extends ConsumerState<CryptoTradeScreen> {
  late int _assetIndex =
      widget.presetAsset != null ? 0 : widget.initialAssetIndex;
  int _toAssetIndex = 1;
  int _sideIndex = 0;
  List<CryptoAsset> _assets = const [];
  bool _seeded = false;
  final _amountController = TextEditingController();

  bool get _isPair =>
      widget.mode == CryptoTradeMode.swap ||
      widget.mode == CryptoTradeMode.convert;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    _loadLivePrices();
  }

  /// Held assets, sourced from the real [AppState] — no [MockData] in
  /// the asset list itself; [MockData.crypto] is only consulted for the
  /// glyph/color/name of the handful of well-known symbols the app
  /// seeds, purely a display nicety.
  List<CryptoAsset> _seedAssets(AppState state) {
    final known = {for (final a in MockData.crypto) a.symbol: a};
    final list = [
      for (final entry in state.cryptoHoldings.entries)
        CryptoAsset(
          symbol: entry.key,
          name: known[entry.key]?.name ?? entry.key,
          glyph: known[entry.key]?.glyph ?? entry.key.substring(0, 1),
          price: state.cryptoPrices[entry.key] ?? known[entry.key]?.price ?? 0,
          changePct: known[entry.key]?.changePct ?? 0,
          holding: _fmtQty(entry.value),
          color: known[entry.key]?.color ?? AppColors.accent,
          logoUrl: known[entry.key]?.logoUrl,
        ),
    ];
    final preset = widget.presetAsset;
    if (preset != null && !list.any((a) => a.symbol == preset.symbol)) {
      return [preset, ...list];
    }
    return list;
  }

  String _fmtQty(double v) {
    if (v == 0) return '0';
    if (v >= 100) return v.toStringAsFixed(0);
    if (v >= 1) return v.toStringAsFixed(2);
    return v.toStringAsFixed(4);
  }

  Future<void> _loadLivePrices() async {
    final appState = ref.read(appStateProvider);
    setState(() {
      _assets = _seedAssets(appState);
      _seeded = true;
      if (_toAssetIndex == _assetIndex && _assets.length > 1) {
        _toAssetIndex = (_assetIndex + 1) % _assets.length;
      }
    });
    try {
      final prices = await CoinGeckoService.getPrices();
      if (!mounted) return;
      setState(() {
        _assets = [
          for (final a in _assets)
            prices.containsKey(a.symbol)
                ? a.copyWith(
                    price: prices[a.symbol]!.price,
                    changePct: prices[a.symbol]!.changePct,
                    logoUrl: prices[a.symbol]!.logoUrl)
                : a,
        ];
      });
    } catch (_) {
      // Falls back to whatever prices AppState already has.
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.mode) {
      case CryptoTradeMode.buy:
        return 'Buy crypto';
      case CryptoTradeMode.swap:
        return 'Swap';
      case CryptoTradeMode.convert:
        return 'Convert';
    }
  }

  String get _subtitle {
    switch (widget.mode) {
      case CryptoTradeMode.buy:
        return 'Pick an asset, enter an amount and choose a funding source.';
      case CryptoTradeMode.swap:
        return 'Instantly swap between assets at live market rates.';
      case CryptoTradeMode.convert:
        return 'Convert any asset to any other asset, including fiat.';
    }
  }

  IconData get _icon {
    switch (widget.mode) {
      case CryptoTradeMode.buy:
        return AppIcons.plus;
      case CryptoTradeMode.swap:
      case CryptoTradeMode.convert:
        return AppIcons.repeat;
    }
  }

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  double get _fee => _amount * _feeRate;

  /// Buy: fiat cost of the amount entered (in USD). Swap/Convert: how
  /// much of the target asset you'll receive.
  double get _estimate {
    final from = _assets[_assetIndex];
    if (!_isPair) return _amount * from.price;
    final to = _assets[_toAssetIndex];
    if (to.price == 0) return 0;
    return (_amount - _fee) * from.price / to.price;
  }

  Future<void> _pickAsset({required bool isTo}) async {
    final picked = await showAppSheet<Object>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose an asset', style: AppText.detailTitle),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.of(ctx).pop(#search),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(AppIcons.search, size: 18, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Text('Search all coins',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent)),
                ],
              ),
            ),
          ),
          Divider(color: AppColors.hairline, height: 18),
          for (int i = 0; i < _assets.length; i++)
            _AssetRow(asset: _assets[i], onTap: () => Navigator.of(ctx).pop(i)),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    if (picked == #search) {
      final coin = await Navigator.of(context).push<CryptoAsset>(
          MaterialPageRoute(builder: (_) => const CoinSearchScreen()));
      if (coin == null || !mounted) return;
      setState(() {
        final existingIndex =
            _assets.indexWhere((a) => a.symbol == coin.symbol);
        final index = existingIndex >= 0 ? existingIndex : _assets.length;
        if (existingIndex < 0) _assets = [..._assets, coin];
        if (isTo) {
          _toAssetIndex = index;
        } else {
          _assetIndex = index;
        }
      });
      return;
    }
    setState(() =>
        isTo ? _toAssetIndex = picked as int : _assetIndex = picked as int);
  }

  Future<void> _confirm() async {
    final asset = _assets[_assetIndex];
    final amountText =
        _amountController.text.trim().isEmpty ? '0' : _amountController.text.trim();

    final confirmed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => PinConfirmScreen(
          title: 'Confirm PIN',
          subtitle: 'Enter your PIN to ${_title.toLowerCase()}'),
    ));
    if (confirmed != true || !mounted) return;

    final notifier = ref.read(appStateProvider.notifier);
    final Future<ProviderResult> Function() task;
    if (!_isPair) {
      final appState = ref.read(appStateProvider);
      final fundingSource = appState.fiatBalances.keys.elementAt(_sideIndex);
      final usdCost = _amount * asset.price;
      final fundingAmount = appState.convert(usdCost, 'USD', fundingSource);
      task = () => notifier.buyCrypto(
          asset: asset.symbol, amount: fundingAmount, fundingSource: fundingSource);
    } else {
      final to = _assets[_toAssetIndex];
      task = () =>
          notifier.swapCrypto(from: asset.symbol, to: to.symbol, amount: _amount);
    }

    final result = await Navigator.of(context).push<ProviderResult>(MaterialPageRoute(
      builder: (_) => ProcessingScreen<ProviderResult>(
        steps: const ['Locking in market price…', 'Executing trade…'],
        task: task,
      ),
    ));
    if (!mounted || result == null) return;
    final failed = result.failed;

    final List<ResultLine> lines;
    final String headline;
    if (!_isPair) {
      final appState = ref.read(appStateProvider);
      final fundingSource = appState.fiatBalances.keys.elementAt(_sideIndex);
      headline = failed ? 'Purchase failed' : 'Purchase complete';
      lines = failed
          ? const []
          : [
              ResultLine('Bought', '$amountText ${asset.symbol}'),
              ResultLine('Paid', '≈\$${_estimate.toStringAsFixed(2)}'),
              ResultLine('Funding source', fundingSource),
            ];
    } else {
      final to = _assets[_toAssetIndex];
      headline = failed ? 'Swap failed' : 'Swap complete';
      lines = failed
          ? const []
          : [
              ResultLine('Swapped', '$amountText ${asset.symbol}'),
              ResultLine('Received', '${_estimate.toStringAsFixed(6)} ${to.symbol}'),
            ];
    }

    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultScreen(
        success: !failed,
        headline: headline,
        detailMessage:
            failed ? result.reason : null,
        lines: lines,
        primaryLabel: failed ? 'Try again' : 'Done',
        onPrimary: () => failed
            ? Navigator.of(context).pop()
            : Navigator.of(context).popUntil((r) => r.isFirst),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!_seeded) {
      return Scaffold(
        backgroundColor: AppColors.page,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }
    final appState = ref.watch(appStateProvider);
    final asset = _assets[_assetIndex];
    final fundingSources = appState.fiatBalances.keys.toList();
    if (_sideIndex >= fundingSources.length) _sideIndex = 0;

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            DetailHeader(icon: _icon, title: _title, subtitle: _subtitle),
            const SizedBox(height: 14),
            const _DemoBadge(),
            const SizedBox(height: 18),
            Text(_isPair ? 'From' : 'Asset', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            _AssetSelector(asset: asset, onTap: () => _pickAsset(isTo: false)),
            if (_isPair) ...[
              const SizedBox(height: 14),
              Center(
                  child:
                      Icon(AppIcons.repeat, size: 20, color: AppColors.muted)),
              const SizedBox(height: 14),
              Text('To', style: AppText.sectionTitle),
              const SizedBox(height: 10),
              _AssetSelector(
                  asset: _assets[_toAssetIndex],
                  onTap: () => _pickAsset(isTo: true)),
            ],
            const SizedBox(height: 22),
            Text('Amount', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style:
                  TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
              decoration:
                  InputDecoration(hintText: '0.00', suffixText: asset.symbol),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration:
                    BoxDecoration(gradient: AppColors.accentGradient),
                child: Stack(
                  children: [
                    Positioned(
                        top: -26,
                        right: -20,
                        child: RingCircle(
                            size: 76,
                            color: Colors.white.withOpacity(0.16),
                            width: 11)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_isPair ? "You'll receive" : "You'll pay",
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            Text('Fee ${(_feeRate * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isPair
                              ? '${_estimate.toStringAsFixed(6)} ${_assets[_toAssetIndex].symbol}'
                              : '\$${_estimate.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                            '1 ${asset.symbol} ≈ \$${asset.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (!_isPair) ...[
              const SizedBox(height: 22),
              Text('Funding source', style: AppText.sectionTitle),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < fundingSources.length; i++)
                    AppChoiceChip(
                        label:
                            '${fundingSources[i]} · ${appState.fiatBalances[fundingSources[i]]!.toStringAsFixed(2)}',
                        selected: i == _sideIndex,
                        onTap: () => setState(() => _sideIndex = i)),
                ],
              ),
            ],
            const SizedBox(height: 28),
            PrimaryButton(
                label: _title, onPressed: _amount > 0 ? _confirm : null),
          ],
        ),
      ),
    );
  }
}

/// Small, honest "this is a demo" signal: real prices, simulated fill —
/// shown right under the header so it reads as a deliberate design
/// choice, not a bug someone forgot to wire up.
class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                const BoxDecoration(color: AppColors.gain, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            'Live market prices · Simulated trade execution',
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

class _AssetSelector extends StatelessWidget {
  const _AssetSelector({required this.asset, required this.onTap});

  final CryptoAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          border: Border.all(color: AppColors.borderStrong),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            TokenBadge(
                glyph: asset.glyph,
                color: asset.color,
                size: 32,
                logoUrl: asset.logoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(asset.name, style: AppText.body),
                  Text(
                      '${asset.holding} ${asset.symbol} available · \$${asset.price.toStringAsFixed(2)}',
                      style: AppText.caption),
                ],
              ),
            ),
            Icon(AppIcons.chevronDown, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({required this.asset, required this.onTap});

  final CryptoAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                size: 32,
                logoUrl: asset.logoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: asset.name, style: AppText.body),
                  TextSpan(
                      text: '  ${asset.symbol}',
                      style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                          fontSize: 11.5)),
                ]),
              ),
            ),
            Text('\$${asset.price.toStringAsFixed(2)}', style: AppText.caption),
          ],
        ),
      ),
    );
  }
}

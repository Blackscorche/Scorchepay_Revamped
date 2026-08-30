import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/device_photo_card.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/detail_header.dart';
import '../../core/widgets/token_badge.dart';
import '../../data/coingecko_service.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class _Buyer {
  const _Buyer(this.name, this.trades, this.completionPct, this.rateAdjust,
      this.minNgn, this.maxNgn, this.method, this.online);
  final String name;
  final int trades;
  final int completionPct;
  final double rateAdjust;
  final int minNgn;
  final int maxNgn;
  final String method;
  final bool online;
}

const _buyers = [
  _Buyer('Tunde_FX', 812, 99, 1.006, 50000, 5000000, 'Bank Transfer', true),
  _Buyer(
      'cryptoQueen_ng', 340, 98, 1.002, 20000, 2000000, 'Bank Transfer', true),
  _Buyer(
      'Ada.trades', 1204, 100, 0.998, 100000, 8000000, 'Bank Transfer', false),
  _Buyer('Bola_p2p', 96, 97, 0.994, 10000, 500000, 'Opay', true),
];

/// Sell crypto peer-to-peer to another ScorchePay user instead of
/// selling to the app — pick an asset and amount, browse buyer offers
/// at their own rates, then walk through the escrow-style order flow.
class P2PSellScreen extends StatefulWidget {
  const P2PSellScreen({super.key, this.initialAssetIndex = 0});

  final int initialAssetIndex;

  @override
  State<P2PSellScreen> createState() => _P2PSellScreenState();
}

class _P2PSellScreenState extends State<P2PSellScreen> {
  late int _assetIndex = widget.initialAssetIndex;
  List<CryptoAsset> _assets = MockData.crypto;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
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
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final asset = _assets[_assetIndex];
    // Live BTC/ETH/etc price is USD — approximate a local NGN rate the
    // same way the rest of the app's mock cross-border rate does.
    const usdToNgn = 1545.20;
    final baseRateNgn = asset.price * usdToNgn;

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            const DetailHeader(
              icon: AppIcons.users,
              title: 'P2P Sell',
              subtitle: 'Sell directly to other ScorchePay users at their rate',
            ),
            const SizedBox(height: 22),
            const Text('Asset', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final picked = await showAppSheet<int>(
                  context,
                  builder: (ctx) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Choose an asset', style: AppText.detailTitle),
                      const SizedBox(height: 10),
                      for (int i = 0; i < _assets.length; i++)
                        GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(i),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                TokenBadge(
                                    glyph: _assets[i].glyph,
                                    color: _assets[i].color,
                                    size: 32,
                                    logoUrl: _assets[i].logoUrl),
                                const SizedBox(width: 12),
                                Text(_assets[i].name, style: AppText.body),
                                const SizedBox(width: 6),
                                Text(_assets[i].symbol,
                                    style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
                if (picked != null) setState(() => _assetIndex = picked);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                    color: AppColors.surface2,
                    border: Border.all(color: AppColors.borderStrong),
                    borderRadius: BorderRadius.circular(14)),
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
                          Text('${asset.holding} ${asset.symbol} available',
                              style: AppText.caption),
                        ],
                      ),
                    ),
                    const Icon(AppIcons.chevronDown,
                        size: 18, color: AppColors.muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text('Amount to sell', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
              decoration:
                  InputDecoration(hintText: '0.00', suffixText: asset.symbol),
            ),
            const SizedBox(height: 22),
            Text('Buyer offers', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            for (final buyer in _buyers)
              _BuyerOfferCard(
                buyer: buyer,
                asset: asset,
                rateNgn: baseRateNgn * buyer.rateAdjust,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => P2POrderScreen(
                    buyerName: buyer.name,
                    method: buyer.method,
                    asset: asset,
                    amount: _amount > 0 ? _amount : 0.01,
                    rateNgn: baseRateNgn * buyer.rateAdjust,
                  ),
                )),
              ),
          ],
        ),
      ),
    );
  }
}

class _BuyerOfferCard extends StatelessWidget {
  const _BuyerOfferCard(
      {required this.buyer,
      required this.asset,
      required this.rateNgn,
      required this.onTap});

  final _Buyer buyer;
  final CryptoAsset asset;
  final double rateNgn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: buyer.online ? AppColors.gain : AppColors.muted,
                      shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: buyer.name,
                          style: AppText.body
                              .copyWith(fontWeight: FontWeight.w700)),
                      TextSpan(
                          text:
                              '  ${buyer.trades} trades · ${buyer.completionPct}%',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11)),
                    ]),
                  ),
                ),
                Text('₦${_formatInt(rateNgn.round())}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Limit ₦${_formatInt(buyer.minNgn)} – ₦${_formatInt(buyer.maxNgn)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(buyer.method,
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatInt(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// The escrow-style order once a buyer offer is picked: the app holds
/// the seller's crypto until the seller confirms the buyer's fiat
/// payment has landed, then releases it.
class P2POrderScreen extends StatefulWidget {
  const P2POrderScreen({
    super.key,
    required this.buyerName,
    required this.method,
    required this.asset,
    required this.amount,
    required this.rateNgn,
  });

  final String buyerName;
  final String method;
  final CryptoAsset asset;
  final double amount;
  final double rateNgn;

  @override
  State<P2POrderScreen> createState() => _P2POrderScreenState();
}

class _P2POrderScreenState extends State<P2POrderScreen> {
  bool _paymentConfirmed = false;
  File? _paymentProofPhoto;

  double get _totalNgn => widget.amount * widget.rateNgn;

  void _release() {
    showAppModal(
      context,
      icon: AppIcons.check,
      iconColor: AppColors.gain,
      title: 'Trade Complete',
      message:
          '${widget.amount} ${widget.asset.symbol} released to ${widget.buyerName}. ₦${_totalNgn.toStringAsFixed(2)} confirmed and settled to your NGN wallet.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            DetailHeader(
                icon: AppIcons.shield,
                title: 'Order · ${widget.buyerName}',
                subtitle: 'Your crypto is held in escrow until you verify payment'),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Selling', '${widget.amount} ${widget.asset.symbol}'),
                  _row('Rate',
                      '₦${_formatInt(widget.rateNgn.round())} / ${widget.asset.symbol}'),
                  _row('Buyer', widget.buyerName),
                  _row('Payment method', widget.method),
                  const Divider(color: AppColors.hairline, height: 24),
                  _row("You'll receive", '₦${_totalNgn.toStringAsFixed(2)}',
                      emphasize: true),
                ],
              ),
            ),
            const SizedBox(height: 18),
            DevicePhotoCard(
              label: 'Buyer Bank Payment Proof (Optional Photo / Screenshot)',
              photo: _paymentProofPhoto,
              onChanged: (file) => setState(() => _paymentProofPhoto = file),
              title: 'Upload Transfer Receipt',
              hint: 'Attach photo/screenshot of bank alert or transfer receipt',
            ),
            const SizedBox(height: 18),
            AppCard(
              color: _paymentConfirmed
                  ? AppColors.gain.withOpacity(0.1)
                  : AppColors.accentSoft,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(_paymentConfirmed ? AppIcons.check : AppIcons.receipt,
                      size: 18,
                      color: _paymentConfirmed
                          ? AppColors.gain
                          : AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _paymentConfirmed
                          ? 'Payment confirmed by you — release the crypto to complete the trade.'
                          : '${widget.buyerName} is paying ₦${_totalNgn.toStringAsFixed(2)} to your bank account now.',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (!_paymentConfirmed)
              PrimaryButton(
                  label: "I've received payment in my bank",
                  onPressed: () => setState(() => _paymentConfirmed = true))
            else
              PrimaryButton(
                label: 'Release crypto to ${widget.buyerName}',
                icon: AppIcons.check,
                onPressed: _release,
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
                fontSize: emphasize ? 16 : 13,
                fontWeight: FontWeight.w800,
                color: emphasize ? AppColors.gain : AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

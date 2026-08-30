import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/choice_chip.dart';
import '../../core/widgets/detail_header.dart';
import '../../core/widgets/photo_picker_sheet.dart';
import '../../state/providers/providers.dart';
import '../../state/services/simulated_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../flows/shared/pin_confirm_screen.dart';
import '../flows/shared/processing_screen.dart';
import '../flows/shared/result_screen.dart';

/// One brand's real identity colors — used instead of a fetched logo
/// image. (Clearbit's free logo API, the obvious choice, shut down in
/// December 2025; its official successor requires a paid API key. Real,
/// stable brand colors with no external dependency beat a fragile
/// third-party image fetch that can break at any time.)
class _Brand {
  const _Brand(this.name, this.color, this.textColor, this.exchangeRate);
  final String name;
  final Color color;
  final Color textColor;

  /// Cash payout as a fraction of face value when exchanging this brand
  /// for cash — mirrors real gift-card exchange platforms, which pay
  /// out at a discount that varies by how liquid/resellable the brand is.
  final double exchangeRate;
}

const _brands = [
  _Brand('Amazon', Color(0xFF131A22), Color(0xFFFF9900), 0.85),
  _Brand('iTunes', Color(0xFFFA233B), Colors.white, 0.78),
  _Brand('Google Play', Color(0xFF01875F), Colors.white, 0.75),
  _Brand('Steam', Color(0xFF1B2838), Color(0xFF66C0F4), 0.70),
  _Brand('Netflix', Colors.black, Color(0xFFE50914), 0.65),
  _Brand('Spotify', Colors.black, Color(0xFF1DB954), 0.65),
];

const _denominations = [25.0, 50.0, 100.0, 200.0];

enum _GiftCardTab { buy, redeem, exchange }

/// Buy, redeem, or exchange (sell for cash) a gift card. Reached from
/// Bills and from Smart Pay's "pay for anything" grid.
class GiftCardScreen extends ConsumerStatefulWidget {
  const GiftCardScreen({super.key});

  @override
  ConsumerState<GiftCardScreen> createState() => _GiftCardScreenState();
}

class _GiftCardScreenState extends ConsumerState<GiftCardScreen> {
  _GiftCardTab _tab = _GiftCardTab.buy;
  int? _brand;
  final _amountController = TextEditingController();
  final _codeController = TextEditingController();
  double? _exchangeDenomination;
  File? _cardPhoto;

  @override
  void dispose() {
    _amountController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    switch (_tab) {
      case _GiftCardTab.redeem:
        return _codeController.text.trim().isNotEmpty;
      case _GiftCardTab.buy:
        return _brand != null && _amountController.text.trim().isNotEmpty;
      case _GiftCardTab.exchange:
        return _brand != null && _exchangeDenomination != null && _codeController.text.trim().isNotEmpty;
    }
  }

  Future<void> _pickPhoto() async {
    final result = await showPhotoPickerSheet(context, title: 'Photo of the card', hasPhoto: _cardPhoto != null);
    if (result == null || !mounted) return;
    setState(() => _cardPhoto = result.removed ? null : result.file);
  }

  Future<void> _submit() async {
    if (_tab == _GiftCardTab.redeem) {
      await showAppModal(context, icon: AppIcons.check, iconColor: AppColors.gain, title: 'Success', message: 'Gift card code redeemed — funds added to your wallet.');
      return;
    }
    if (_tab == _GiftCardTab.buy) {
      await showAppModal(context, icon: AppIcons.check, iconColor: AppColors.gain, title: 'Success', message: '\$${_amountController.text.trim()} ${_brands[_brand!].name} gift card purchased.');
      return;
    }

    // Exchange — real PIN → processing → result flow, since real money
    // is landing in the wallet.
    final brand = _brands[_brand!];
    final faceValue = _exchangeDenomination!;
    final payout = faceValue * brand.exchangeRate * 1545.20; // USD -> NGN at the live-ish rate used elsewhere

    final confirmed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => PinConfirmScreen(title: 'Confirm PIN', subtitle: 'Enter your PIN to exchange this \$${faceValue.toStringAsFixed(0)} ${brand.name} card'),
    ));
    if (confirmed != true || !mounted) return;

    final notifier = ref.read(appStateProvider.notifier);
    final result = await Navigator.of(context).push<ProviderResult>(MaterialPageRoute(
      builder: (_) => ProcessingScreen<ProviderResult>(
        steps: const ['Verifying card code…', 'Confirming balance with issuer…'],
        task: () => notifier.exchangeGiftCard(brand: brand.name, faceValueUsd: faceValue, payoutNaira: payout),
      ),
    ));
    if (!mounted) return;

    final failed = result?.failed ?? true;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultScreen(
        success: !failed,
        headline: failed ? 'Exchange failed' : 'Card exchanged',
        detailMessage: failed ? 'Could not verify this card with the issuer — check the code and try again.' : null,
        lines: failed
            ? const []
            : [
                ResultLine('Card', '${brand.name} · \$${faceValue.toStringAsFixed(0)}'),
                ResultLine('Payout', '₦${payout.toStringAsFixed(2)}'),
              ],
        primaryLabel: failed ? 'Try again' : 'Done',
        onPrimary: () => failed ? Navigator.of(context).pop() : Navigator.of(context).popUntil((r) => r.isFirst),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            const DetailHeader(icon: AppIcons.giftCard, title: 'Gift Cards', subtitle: 'Buy, redeem, or exchange gift cards for cash'),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(13)),
              child: Row(
                children: [
                  Expanded(child: _Tab(label: 'Buy', selected: _tab == _GiftCardTab.buy, onTap: () => setState(() => _tab = _GiftCardTab.buy))),
                  Expanded(child: _Tab(label: 'Redeem', selected: _tab == _GiftCardTab.redeem, onTap: () => setState(() => _tab = _GiftCardTab.redeem))),
                  Expanded(child: _Tab(label: 'Exchange', selected: _tab == _GiftCardTab.exchange, onTap: () => setState(() => _tab = _GiftCardTab.exchange))),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (_tab == _GiftCardTab.redeem) ...[
              const Text('Gift card code', style: AppText.sectionTitle),
              const SizedBox(height: 10),
              TextField(
                controller: _codeController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Enter the code on your card'),
              ),
            ] else ...[
              const Text('Brand', style: AppText.sectionTitle),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  for (int i = 0; i < _brands.length; i++)
                    _BrandTile(brand: _brands[i], selected: i == _brand, onTap: () => setState(() => _brand = i)),
                ],
              ),
              if (_tab == _GiftCardTab.buy) ...[
                const SizedBox(height: 22),
                const Text('Amount', style: AppText.sectionTitle),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '0.00', prefixText: '\$'),
                ),
              ] else ...[
                const SizedBox(height: 22),
                const Text('Card value', style: AppText.sectionTitle),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final d in _denominations)
                      AppChoiceChip(label: '\$${d.toStringAsFixed(0)}', selected: d == _exchangeDenomination, onTap: () => setState(() => _exchangeDenomination = d)),
                  ],
                ),
                const SizedBox(height: 22),
                const Text('Gift card code', style: AppText.sectionTitle),
                const SizedBox(height: 10),
                TextField(
                  controller: _codeController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'Enter the code on the back of the card'),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _pickPhoto,
                  child: _cardPhoto == null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(color: AppColors.surface2, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14)),
                          child: const Row(
                            children: [
                              Icon(AppIcons.camera, size: 18, color: AppColors.muted),
                              SizedBox(width: 10),
                              Text('Attach a photo of the card (optional)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_cardPhoto!, width: double.infinity, height: 120, fit: BoxFit.cover),
                        ),
                ),
                if (_brand != null && _exchangeDenomination != null) ...[
                  const SizedBox(height: 18),
                  AppCard(
                    color: AppColors.accentSoft,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('You\'ll receive (${(_brands[_brand!].exchangeRate * 100).toStringAsFixed(0)}% rate)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('₦${(_exchangeDenomination! * _brands[_brand!].exchangeRate * 1545.20).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ],
            ],
            const SizedBox(height: 28),
            PrimaryButton(
              label: switch (_tab) { _GiftCardTab.redeem => 'Redeem card', _GiftCardTab.buy => 'Buy gift card', _GiftCardTab.exchange => 'Exchange for cash' },
              onPressed: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(color: selected ? AppColors.surface3 : null, borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? AppColors.textPrimary : AppColors.textSecondary)),
      ),
    );
  }
}

class _BrandTile extends StatelessWidget {
  const _BrandTile({required this.brand, required this.selected, required this.onTap});

  final _Brand brand;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: brand.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.accent : Colors.transparent, width: 2),
          boxShadow: selected ? [BoxShadow(color: AppColors.accent.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))] : null,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          brand.name,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: brand.textColor, letterSpacing: -0.2),
        ),
      ),
    );
  }
}

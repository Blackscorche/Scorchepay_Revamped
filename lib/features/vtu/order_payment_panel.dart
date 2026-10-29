import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/async_action.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../state/models/connected_wallet.dart';
import '../../state/models/vtu.dart';
import '../../state/providers/vtu_providers.dart';
import '../../state/providers/api_providers.dart';
import '../../state/providers/wallets_provider.dart';
import '../../state/services/wallet_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'pay_from_wallet.dart';
import 'vtu_ui.dart';

/// Whether [order]'s quote can still be paid: unpaid and not yet expired
/// here, even if the backend hasn't reported it expired yet.
bool canPayNow(VtuOrder order) =>
    order.status == OrderStatus.awaitingPayment &&
    order.timeLeft() > Duration.zero;

/// The order screen's payment step, for an unpaid order: the quote
/// (fiat, sats and a countdown) and the wallet to pay from (the current
/// one by default, switchable, with balances). The screen's action bar
/// holds the buttons, run by [OrderPaymentActions].
class OrderPaymentPanel extends StatelessWidget {
  const OrderPaymentPanel({
    super.key,
    required this.order,
    required this.wallet,
    required this.onWalletChanged,
  });

  /// Awaiting payment or expired.
  final VtuOrder order;

  /// The wallet to pay from; null when none is connected.
  final ConnectedWallet? wallet;
  final ValueChanged<String> onWalletChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 22,
      children: [
        AppCard(
          child: Column(
            spacing: 6,
            children: [
              Text(formatFiat(order.amount, order.currency),
                  style: AppText.heroNumber.copyWith(fontSize: 32)),
              Text(formatSats(order.sats),
                  style: AppText.body.copyWith(
                      color: AppColors.accent, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              QuoteCountdown(expiresAt: order.expiresAt),
            ],
          ),
        ),
        if (canPayNow(order))
          switch (wallet) {
            final wallet? => PayFromWalletCard(
                wallet: wallet,
                requiredSats: order.sats,
                onChanged: onWalletChanged,
              ),
            null => const ConnectWalletNotice(),
          },
      ],
    );
  }
}

/// Paying, simulating payment and requoting for the order screen, kept
/// out of the screen itself. Also rebuilds the screen every second so Pay
/// turns into "Get a new quote" the moment a quote runs out, without
/// waiting for the next poll.
mixin OrderPaymentActions<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, AsyncActionMixin<T> {
  /// The wallet picked to pay from; null means the current wallet.
  String? payingWalletId;

  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void selectPayingWallet(String walletId) {
    clearActionError();
    setState(() => payingWalletId = walletId);
  }

  /// Polls [orderId] again now (and resumes polling if it had stopped).
  void _refreshOrder(String orderId) {
    ref.invalidate(orderProvider(orderId));
    ref.invalidate(recentOrdersProvider);
  }

  /// Sends [order]'s invoice to [wallet] over NWC.
  Future<void> payOrder(VtuOrder order, ConnectedWallet wallet) async {
    final uri = ref.read(walletsProvider.notifier).connectionUri(wallet.id);
    if (uri == null) return;
    final result = await runAction(() => ref
        .read(walletServiceProvider)
        // Wallets that ask the user to approve may take a while; stop
        // waiting when the quote (and so the invoice) expires.
        .payInvoice(uri, order.invoice, timeout: order.timeLeft()));
    if (!mounted) return;
    ref.invalidate(walletBalanceProvider(wallet.id));
    _refreshOrder(order.id);
    if (!result.hasError) return;

    // The backend holds the payment until the bill is delivered, so the
    // wallet only answers once it's settled, and a bill that couldn't be
    // delivered comes back as a failed payment. The order is the truth:
    // the wallet's error only stands if the order is still unpaid. A
    // timeout isn't a failure either: the wallet may still be paying.
    final error = result.error;
    final timedOut =
        error is WalletException && error.code == WalletErrorCode.timeout;
    final stillUnpaid = timedOut ? false : await _stillUnpaid(order.id);
    if (mounted && !stillUnpaid) clearActionError();
  }

  /// Whether [orderId] is still awaiting payment, per the backend. Unknown
  /// (e.g. offline) counts as unpaid, so the wallet's error stays shown.
  Future<bool> _stillUnpaid(String orderId) async {
    try {
      final order = await ref.read(vtuApiProvider).getOrder(orderId);
      return order.status == OrderStatus.awaitingPayment;
    } catch (_) {
      return true;
    }
  }

  /// Debug ([ApiFeatures.simulatePayments]): settles the invoice without
  /// a wallet, e.g. when no wallet can pay the backend's test-network
  /// invoices.
  Future<void> simulatePayment(VtuOrder order) async {
    final result = await runAction(
        () => ref.read(vtuApiProvider).simulatePayment(order.id));
    if (mounted && result.hasValue) _refreshOrder(order.id);
  }

  /// A fresh quote and invoice on the same order.
  Future<void> requoteOrder(VtuOrder order) async {
    final result =
        await runAction(() => ref.read(vtuApiProvider).requote(order.id));
    if (mounted && result.hasValue) _refreshOrder(order.id);
  }
}

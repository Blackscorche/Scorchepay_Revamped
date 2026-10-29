import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/app_notification.dart';
import '../models/automation.dart';
import '../models/escrow.dart';
import '../models/ledger_entry.dart';
import '../models/savings.dart';
import '../services/automation_service.dart';
import '../services/backend_service.dart';
import '../services/escrow_service.dart';
import '../services/fx_rate_service.dart';
import '../services/ledger_service.dart';
import '../services/local_store.dart';
import '../services/savings_service.dart';
import '../services/simulated_providers.dart';
import '../services/smart_pay_engine.dart';
import 'app_state.dart';

/// The app's one state notifier: the signed-in user from the backend
/// ([backendProvider], which also handles signing in and out) combined
/// with the device's local data, plus every user-facing action on that
/// local data.
///
/// [build] waits for the backend's session, so this is loading until
/// that's done; ScorchePayApp shows the splash until then. Everything else
/// reads it through `requireValue`.
final appStateProvider =
    AsyncNotifierProvider<AppStateNotifier, AppState>(AppStateNotifier.new);

const _uuid = Uuid();

/// Every action follows one pattern: mutate the current state's
/// internals via the relevant service, then [_commit], which publishes a
/// clone (so Riverpod always notifies, despite the mutable internals) and
/// persists the device-local slice to disk. Backend data — identity and
/// the token — is never written to [LocalStore].
class AppStateNotifier extends AsyncNotifier<AppState> {
  LocalStore get _store => ref.read(localStoreProvider);

  /// The current state. Actions only run once [build] has completed.
  AppState get _appState => state.requireValue;

  @override
  Future<AppState> build() async {
    // Failures propagate: the provider goes into AsyncError (keeping the
    // previous value on a reload), and ScorchePayApp shows the error and
    // decides whether to recover via [continueSignedOut].
    final local = await _store.load();
    final session = await ref.watch(backendProvider.future);
    if (session == null) return AppState.signedOut(local);

    final user = session.user;
    final localState = local.username == user.username
        ? local
        : local.cloneWith(username: user.username);
    if (localState != local) {
      // Persist parts of the state (like username) gotten from the backend
      // but used on the client.
      await _store.save(localState);
    }

    // Run after refreshing state
    unawaited(Future(_refreshFxRates));
    return AppState(
      token: session.token,
      userId: user.id,
      displayName: user.displayName,
      kyc: user.kyc,
      photoUrl: user.photoUrl,
      localState: localState,
    );
  }

  /// Recovers from a failed [build] by continuing signed out on the
  /// device's data, so the app stays usable. Called by ScorchePayApp
  /// after it has shown the error.
  Future<void> continueSignedOut() async {
    state = AsyncData(AppState.signedOut(await _store.load()));
  }

  /// Pulls live NGN-pivot FX rates (§5 of the spec — real rates, not a
  /// static table) and merges them into whatever currencies the user
  /// already holds. Falls back silently to the existing bundled rates
  /// on any failure (offline, rate-limited), same pattern as
  /// [CoinGeckoService].
  Future<void> _refreshFxRates() async {
    try {
      if (_appState.localState.fxRatesToNgn.isEmpty) return;
      final live = await FxRateService.getRatesToNgn();
      for (final code in _appState.localState.fxRatesToNgn.keys.toList()) {
        if (live.containsKey(code)) {
          _appState.localState.fxRatesToNgn[code] = live[code]!;
        }
      }
      await _commit();
    } catch (_) {
      // Offline or the free API is down — the bundled rates already cover it.
    }
  }

  Future<void> _commit() async {
    state = AsyncData(_appState.clone());
    // Only the device-local slice is written (see LocalStore).
    await _store.save(_appState.localState);
  }

  // ---------------------------------------------------------------------
  // Smart Pay / bills
  // ---------------------------------------------------------------------

  Future<SmartPayResult> payBill(
      {required String biller,
      required String customerId,
      required double amount,
      required String currency,
      String? fixedSourceCurrency}) async {
    try {
      final result = await SmartPayEngine.payBill(_appState,
          biller: biller,
          customerId: customerId,
          amount: amount,
          currency: currency,
          fixedSourceCurrency: fixedSourceCurrency);
      await _commit();
      return result;
    } on InsufficientFundsException catch (ex) {
      return SmartPayResult.insufficientFunds(FundingPlan(
          nativeCurrency: currency,
          nativeAmount: amount,
          legs: const [],
          shortBy: ex.shortBy));
    }
  }

  FundingPlan planPayment(
      {required String nativeCurrency,
      required double nativeAmount,
      String? fixedSourceCurrency}) {
    return SmartPayEngine.planPayment(_appState,
        nativeCurrency: nativeCurrency,
        nativeAmount: nativeAmount,
        fixedSourceCurrency: fixedSourceCurrency);
  }

  // ---------------------------------------------------------------------
  // Send Money
  // ---------------------------------------------------------------------

  /// Explicit demo repository. Live transfers use the server-owned operation API.
  Future<bool> sendInternal(
      {required String toUsername,
      required String toDisplayName,
      required String currency,
      required double amount,
      String? note}) async {
    try {
      LedgerService.internalTransferOut(_appState,
          currency: currency,
          amount: amount,
          recipientUsername: toUsername,
          recipientDisplayName: toDisplayName,
          note: note);
      await _recordLocalSendNotification(
          currency: currency, amount: amount, toDisplayName: toDisplayName);
      await _commit();
      return true;
    } on InsufficientFundsException {
      return false;
    }
  }

  Future<void> _recordLocalSendNotification(
      {required String currency,
      required double amount,
      required String toDisplayName}) async {
    _appState.localState.notifications.insert(
        0,
        AppNotification(
            id: _uuid.v4(),
            at: DateTime.now(),
            category: NotificationCategory.transfers,
            title: 'Money sent',
            body:
                '${amount.toStringAsFixed(2)} $currency sent to $toDisplayName.'));
  }

  Future<ProviderResult> sendToBank(
      {required double amount,
      required String bankName,
      required String accountName}) async {
    try {
      final entry = LedgerService.debit(_appState,
          currency: 'NGN',
          amount: amount,
          title: 'Sent to $accountName',
          subtitle: '$bankName · bank transfer',
          category: LedgerCategory.transfer);
      final result = await SimulatedProviders.bankTransfer(
          amount: amount, bankName: bankName);
      if (result.failed) {
        LedgerService.refund(_appState, entry, reasonSuffix: result.reason);
        _appState.localState.notifications.insert(
            0,
            AppNotification(
                id: _uuid.v4(),
                at: DateTime.now(),
                category: NotificationCategory.transfers,
                title: 'Transfer failed',
                body:
                    '${result.reason} — ${amount.toStringAsFixed(2)} NGN refunded.'));
      } else {
        _appState.localState.notifications.insert(
            0,
            AppNotification(
                id: _uuid.v4(),
                at: DateTime.now(),
                category: NotificationCategory.transfers,
                title: 'Transfer sent',
                body:
                    '${amount.toStringAsFixed(2)} NGN sent to $accountName ($bankName).'));
      }
      await _commit();
      return result;
    } on InsufficientFundsException {
      await _commit();
      return const ProviderResult.failure('Insufficient funds');
    }
  }

  // ---------------------------------------------------------------------
  // Crypto
  // ---------------------------------------------------------------------

  Future<ProviderResult> buyCrypto(
      {required String asset,
      required double amount,
      required String fundingSource}) async {
    try {
      final entry = LedgerService.debit(_appState,
          currency: fundingSource,
          amount: amount,
          title: 'Buy $asset',
          subtitle: 'Crypto purchase',
          category: LedgerCategory.crypto);
      final result =
          await SimulatedProviders.executeTrade(asset: asset, amount: amount);
      if (result.failed) {
        LedgerService.refund(_appState, entry, reasonSuffix: result.reason);
      } else {
        final price = _appState.localState.cryptoPrices[asset] ?? 1;
        final usdValue = _appState.convert(amount, fundingSource, 'USD');
        final qty = usdValue / price;
        LedgerService.credit(_appState,
            currency: asset,
            amount: qty,
            title: 'Bought $asset',
            subtitle: 'Crypto purchase',
            category: LedgerCategory.crypto);
      }
      await _commit();
      return result;
    } on InsufficientFundsException {
      await _commit();
      return const ProviderResult.failure('Insufficient funds');
    }
  }

  Future<ProviderResult> sellCrypto(
      {required String asset,
      required double quantity,
      required String payoutCurrency}) async {
    try {
      final entry = LedgerService.debit(_appState,
          currency: asset,
          amount: quantity,
          title: 'Sell $asset',
          subtitle: 'Crypto sale',
          category: LedgerCategory.crypto);
      final result =
          await SimulatedProviders.executeTrade(asset: asset, amount: quantity);
      if (result.failed) {
        LedgerService.refund(_appState, entry, reasonSuffix: result.reason);
      } else {
        final usdValue =
            quantity * (_appState.localState.cryptoPrices[asset] ?? 1);
        final payout = _appState.convert(usdValue, 'USD', payoutCurrency);
        LedgerService.credit(_appState,
            currency: payoutCurrency,
            amount: payout,
            title: 'Sold $asset',
            subtitle: 'Crypto sale',
            category: LedgerCategory.crypto);
      }
      await _commit();
      return result;
    } on InsufficientFundsException {
      await _commit();
      return const ProviderResult.failure('Insufficient funds');
    }
  }

  Future<ProviderResult> swapCrypto(
      {required String from,
      required String to,
      required double amount}) async {
    try {
      final entry = LedgerService.debit(_appState,
          currency: from,
          amount: amount,
          title: 'Swap $from → $to',
          subtitle: 'Crypto swap',
          category: LedgerCategory.crypto);
      final result =
          await SimulatedProviders.executeTrade(asset: from, amount: amount);
      if (result.failed) {
        LedgerService.refund(_appState, entry, reasonSuffix: result.reason);
      } else {
        final converted = _appState.convert(amount, from, to);
        LedgerService.credit(_appState,
            currency: to,
            amount: converted,
            title: 'Swapped to $to',
            subtitle: 'From $from',
            category: LedgerCategory.crypto);
      }
      await _commit();
      return result;
    } on InsufficientFundsException {
      await _commit();
      return const ProviderResult.failure('Insufficient funds');
    }
  }

  Future<ProviderResult> withdrawCrypto(
      {required String asset,
      required double amount,
      required String network,
      required String address}) async {
    try {
      LedgerService.debit(_appState,
          currency: asset,
          amount: amount,
          title: 'Withdraw $asset',
          subtitle: '$network · $address',
          category: LedgerCategory.crypto,
          meta: {'network': network, 'address': address});
      final result = await SimulatedProviders.broadcastWithdrawal(
          asset: asset, network: network);
      _appState.localState.notifications.insert(
          0,
          AppNotification(
              id: _uuid.v4(),
              at: DateTime.now(),
              category: NotificationCategory.withdrawals,
              title: 'Withdrawal broadcast',
              body: '$amount $asset submitted to $network.'));
      await _commit();
      return result;
    } on InsufficientFundsException {
      await _commit();
      return const ProviderResult.failure('Insufficient funds');
    }
  }

  Future<ProviderResult> crossBorderTransfer(
      {required double amount,
      required String corridor,
      required String recipientName}) async {
    try {
      final entry = LedgerService.debit(_appState,
          currency: 'NGN',
          amount: amount,
          title: 'Cross-border to $recipientName',
          subtitle: corridor,
          category: LedgerCategory.transfer);
      final result = await SimulatedProviders.crossBorderTransfer(
          amount: amount, corridor: corridor);
      if (result.failed) {
        LedgerService.refund(_appState, entry, reasonSuffix: result.reason);
      }
      await _commit();
      return result;
    } on InsufficientFundsException {
      await _commit();
      return const ProviderResult.failure('Insufficient funds');
    }
  }

  /// Sells a gift card for cash at a discount off face value — the
  /// reverse of buying one. Real gift-card exchange platforms (in
  /// Nigeria: CardtoNaira, Prestmit) work exactly this way: the payout
  /// is computed and shown before the user commits, the card
  /// code/photo is submitted, and cash lands once the (simulated here)
  /// verification step passes.
  Future<ProviderResult> exchangeGiftCard({
    required String brand,
    required double faceValueUsd,
    required double payoutNaira,
  }) async {
    final result = await SimulatedProviders.executeTrade(
        asset: brand, amount: faceValueUsd);
    if (result.failed) return result;
    LedgerService.credit(
      _appState,
      currency: 'NGN',
      amount: payoutNaira,
      title: 'Gift card exchanged — $brand',
      subtitle: '\$${faceValueUsd.toStringAsFixed(0)} card',
      category: LedgerCategory.bill,
    );
    _appState.localState.notifications.insert(
        0,
        AppNotification(
            id: _uuid.v4(),
            at: DateTime.now(),
            category: NotificationCategory.deposits,
            title: 'Gift card exchanged',
            body:
                '₦${payoutNaira.toStringAsFixed(2)} credited for your \$${faceValueUsd.toStringAsFixed(0)} $brand card.'));
    await _commit();
    return result;
  }

  // ---------------------------------------------------------------------
  // Escrow
  // ---------------------------------------------------------------------

  Future<String> createEscrow({
    required String escrowType,
    required String counterpartyUsername,
    required String counterpartyName,
    required EscrowRole role,
    required String description,
    required String currency,
    required List<EscrowMilestone> milestones,
  }) async {
    final id = EscrowService.create(_appState,
        escrowType: escrowType,
        counterpartyUsername: counterpartyUsername,
        counterpartyName: counterpartyName,
        role: role,
        description: description,
        currency: currency,
        milestones: milestones);
    await _commit();
    return id;
  }

  Future<void> respondToEscrow(String escrowId, {required bool accept}) async {
    EscrowService.counterpartyRespond(_appState, escrowId, accept: accept);
    await _commit();
  }

  Future<SmartPayResult> fundEscrow(String escrowId) async {
    try {
      final result = EscrowService.fund(_appState, escrowId);
      await _commit();
      return result;
    } on InsufficientFundsException catch (ex) {
      final e = EscrowService.find(_appState, escrowId);
      return SmartPayResult.insufficientFunds(FundingPlan(
          nativeCurrency: e?.currency ?? '',
          nativeAmount: e?.totalAmount ?? 0,
          legs: const [],
          shortBy: ex.shortBy));
    }
  }

  Future<void> simulateCounterpartyFundEscrow(String escrowId) async {
    EscrowService.simulateCounterpartyFund(_appState, escrowId);
    await _commit();
  }

  Future<void> submitEscrowEvidence(
      String escrowId, String milestoneId, String note,
      {bool bySimulatedCounterparty = false}) async {
    EscrowService.submitEvidence(_appState, escrowId, milestoneId, note,
        bySimulatedCounterparty: bySimulatedCounterparty);
    await _commit();
  }

  Future<void> releaseEscrowMilestone(
      String escrowId, String milestoneId) async {
    EscrowService.release(_appState, escrowId, milestoneId);
    await _commit();
  }

  Future<void> raiseEscrowDispute(
      String escrowId, String milestoneId, String reason,
      {bool bySimulatedCounterparty = false}) async {
    EscrowService.raiseDispute(_appState, escrowId, milestoneId, reason,
        bySimulatedCounterparty: bySimulatedCounterparty);
    await _commit();
  }

  Future<void> resolveEscrowDispute(
      String escrowId, String milestoneId, DisputeResolution resolution) async {
    EscrowService.resolveDispute(_appState, escrowId, milestoneId, resolution);
    await _commit();
  }

  Future<void> checkExpiredReviewWindows() async {
    final before =
        _appState.localState.escrows.map((e) => e.timeline.length).toList();
    EscrowService.checkExpiredReviewWindows(_appState);
    final after =
        _appState.localState.escrows.map((e) => e.timeline.length).toList();
    if (before.toString() != after.toString()) await _commit();
  }

  // ---------------------------------------------------------------------
  // Savings
  // ---------------------------------------------------------------------

  Future<String> createSavingsGoal(SavingsGoal goal) async {
    final id = SavingsService.create(_appState, goal);
    await _commit();
    return id;
  }

  Future<SmartPayResult> contributeSavings(String goalId, double amount,
      {String? fundingSource}) async {
    try {
      final result = SavingsService.contribute(_appState, goalId, amount,
          fundingSource: fundingSource);
      await _commit();
      return result;
    } on InsufficientFundsException catch (ex) {
      return SmartPayResult.insufficientFunds(FundingPlan(
          nativeCurrency: fundingSource ?? '',
          nativeAmount: amount,
          legs: const [],
          shortBy: ex.shortBy));
    }
  }

  Future<double> withdrawSavings(String goalId, double amount) async {
    final net = SavingsService.withdraw(_appState, goalId, amount);
    await _commit();
    return net;
  }

  Future<void> deleteSavingsGoal(String goalId) async {
    SavingsService.deleteGoal(_appState, goalId);
    await _commit();
  }

  Future<void> groupContribute(String goalId, String memberUsername,
      {bool bySimulated = true}) async {
    SavingsService.groupContribute(_appState, goalId, memberUsername,
        bySimulated: bySimulated);
    await _commit();
  }

  // ---------------------------------------------------------------------
  // Automation
  // ---------------------------------------------------------------------

  Future<String> createAutomationRule(AutomationRule rule) async {
    final id = AutomationService.create(_appState, rule);
    await _commit();
    return id;
  }

  Future<void> pauseRule(String id) async {
    AutomationService.pause(_appState, id);
    await _commit();
  }

  Future<void> resumeRule(String id) async {
    AutomationService.resume(_appState, id);
    await _commit();
  }

  Future<void> deleteRule(String id) async {
    AutomationService.delete(_appState, id);
    await _commit();
  }

  Future<void> runRuleNow(String id) async {
    await AutomationService.runRuleNow(_appState, id);
    await _commit();
  }

  Future<void> runDueRules() async {
    await AutomationService.runDueRules(_appState);
    await _commit();
  }

  // ---------------------------------------------------------------------
  // Misc
  // ---------------------------------------------------------------------

  Future<void> toggleHideBalance() async {
    _appState.localState.hideBalance = !_appState.localState.hideBalance;
    await _commit();
  }

  Future<void> onCompleteOnboarding() async {
    _appState.localState.showOnboarding = false;
    await _commit();
  }

  Future<void> markNotificationRead(String id) async {
    for (final n in _appState.localState.notifications) {
      if (n.id == id) n.read = true;
    }
    await _commit();
  }

  Future<void> markAllNotificationsRead() async {
    for (final n in _appState.localState.notifications) {
      n.read = true;
    }
    await _commit();
  }
}

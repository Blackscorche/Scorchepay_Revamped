import 'dart:math';

/// Stands in for every real external integration this prototype doesn't
/// have a backend for — the payments/FX provider, the crypto liquidity
/// provider, biller APIs, NIBSS bank rails. Every method returns after an
/// artificial delay and a probabilistic outcome, so the UI has to handle
/// these as real async operations with real failure paths (per the spec's
/// repeated point: never treat "submitted" as "done").
class ProviderResult {
  const ProviderResult.success([this.reference])
      : failed = false,
        reason = null;
  const ProviderResult.failure(this.reason)
      : failed = true,
        reference = null;

  final bool failed;
  final String? reference;
  final String? reason;
}

class SimulatedProviders {
  SimulatedProviders._();

  static final Random _rand = Random();

  static Future<void> _delay([int minMs = 400, int maxMs = 1100]) {
    final ms = minMs + _rand.nextInt(maxMs - minMs);
    return Future.delayed(Duration(milliseconds: ms));
  }

  /// A bill payment / biller API call — vends airtime, data, electricity
  /// tokens, etc. ~92% success rate.
  static Future<ProviderResult> payBill(
      {required String biller, required double amount}) async {
    await _delay(500, 1400);
    if (_rand.nextDouble() < 0.92) {
      return ProviderResult.success('TKN-${_rand.nextInt(900000) + 100000}');
    }
    return const ProviderResult.failure('Biller temporarily unavailable');
  }

  /// Domestic bank transfer via NIBSS-style instant rails. ~95% success.
  static Future<ProviderResult> bankTransfer(
      {required double amount, required String bankName}) async {
    await _delay(400, 1000);
    if (_rand.nextDouble() < 0.95) {
      return ProviderResult.success('NIBSS-${_rand.nextInt(900000) + 100000}');
    }
    return const ProviderResult.failure('Recipient bank unavailable');
  }

  /// Crypto liquidity provider — buy/sell/swap execution. ~96% success.
  static Future<ProviderResult> executeTrade(
      {required String asset, required double amount}) async {
    await _delay(300, 900);
    if (_rand.nextDouble() < 0.96) {
      return ProviderResult.success();
    }
    return const ProviderResult.failure(
        'Liquidity unavailable at this instant');
  }

  /// On-chain broadcast for an external crypto withdrawal — always
  /// "succeeds" at the broadcast step (funds already left the user's
  /// balance per spec §6), simulating network confirmation time.
  static Future<ProviderResult> broadcastWithdrawal(
      {required String asset, required String network}) async {
    await _delay(600, 1500);
    return ProviderResult.success(
        '0x${_rand.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}…');
  }

  /// Cross-border settlement — slower, occasionally fails on
  /// recipient-side detail issues.
  static Future<ProviderResult> crossBorderTransfer(
      {required double amount, required String corridor}) async {
    await _delay(900, 1800);
    if (_rand.nextDouble() < 0.9) {
      return ProviderResult.success('XB-${_rand.nextInt(900000) + 100000}');
    }
    return const ProviderResult.failure('Recipient bank details invalid');
  }

  /// FX / conversion quote — locked for [lockSeconds]. Simulated with a
  /// small deterministic-ish spread so repeated quotes vary slightly,
  /// like a real live rate would.
  static double quoteRate(
      {required String from, required String to, required double baseRate}) {
    final wobble = 1 + (_rand.nextDouble() - 0.5) * 0.004; // +/-0.2%
    return baseRate * wobble;
  }
}

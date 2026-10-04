import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/detail_header.dart';
import '../../state/services/bitcoin_wallet_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// A real, working Bitcoin Signet (testnet) wallet — genuinely
/// generates keys, syncs a live chain indexer and can send a real
/// Signet transaction. Kept as its own standalone screen with no
/// dependency on the rest of the app's simulated state, so it has the
/// fewest possible things that can go wrong live.
class BitcoinWalletScreen extends StatefulWidget {
  const BitcoinWalletScreen({super.key});

  @override
  State<BitcoinWalletScreen> createState() => _BitcoinWalletScreenState();
}

class _BitcoinWalletScreenState extends State<BitcoinWalletScreen> {
  final _service = BitcoinWalletService.instance;

  bool _loading = true;
  bool _syncing = false;
  String? _address;
  BigInt _balanceSat = BigInt.zero;
  BigInt _pendingSat = BigInt.zero;
  List<TransactionDetailsView> _txs = const [];
  String? _newMnemonicToShow;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final existing = await _service.loadExisting();
    if (existing == null) {
      setState(() => _loading = false);
      return;
    }
    await _refresh();
    setState(() => _loading = false);
    unawaited(_sync());
  }

  Future<void> _createWallet() async {
    setState(() => _loading = true);
    final (_, phrase) = await _service.createNew();
    setState(() {
      _newMnemonicToShow = phrase;
      _loading = false;
    });
    await _refresh();
    unawaited(_sync());
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      await _service.sync();
      await _refresh();
    } catch (_) {
      // Offline or indexer hiccup — balance just stays as last synced.
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _refresh() async {
    if (!_service.isLoaded) return;
    final address = _service.getReceiveAddress();
    final balance = _service.getBalance();
    final txs = _service.getTransactions();
    setState(() {
      _address = address.address.toString();
      _balanceSat = balance.confirmed;
      _pendingSat = balance.trustedPending + balance.untrustedPending;
      _txs = txs
          .map((t) => TransactionDetailsView(
                txid: t.txid,
                netSat: t.received - t.sent,
                confirmed: t.confirmationTime != null,
              ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: AppColors.accent))
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
                children: [
                  const DetailHeader(
                    icon: AppIcons.bitcoin,
                    title: 'Bitcoin (Signet)',
                    subtitle: 'A real testnet wallet — no real funds involved',
                  ),
                  const SizedBox(height: 20),
                  if (_newMnemonicToShow != null) ...[
                    _BackupPhraseCard(
                      phrase: _newMnemonicToShow!,
                      onDismiss: () => setState(() => _newMnemonicToShow = null),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_address == null)
                    _EmptyWalletCard(onCreate: _createWallet)
                  else
                    ..._buildWallet(),
                ],
              ),
      ),
    );
  }

  List<Widget> _buildWallet() {
    return [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('BALANCE (SIGNET)',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                        letterSpacing: 0.7)),
                GestureDetector(
                  onTap: _syncing ? null : _sync,
                  child: Row(
                    children: [
                      if (_syncing)
                        SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.accent))
                      else
                        Icon(Icons.sync_rounded, size: 14, color: AppColors.accent),
                      const SizedBox(width: 5),
                      Text(_syncing ? 'Syncing…' : 'Sync',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${_balanceSat.toString()} sats',
                style: AppText.heroNumber.copyWith(fontSize: 30)),
            if (_pendingSat > BigInt.zero) ...[
              const SizedBox(height: 4),
              Text('+ $_pendingSat sats pending',
                  style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
            ],
          ],
        ),
      ),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RECEIVE',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    letterSpacing: 0.7)),
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(
                    data: _address!, size: 190, backgroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _address!));
                showAppModal(context,
                    icon: AppIcons.check,
                    iconColor: AppColors.gain,
                    title: 'Copied',
                    message: 'Signet address copied to clipboard.');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_address!,
                          style: TextStyle(
                              fontSize: 11.5,
                              fontFamily: 'monospace',
                              color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Icon(AppIcons.copy, size: 15, color: AppColors.accent),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      PrimaryButton(
        label: 'Send',
        icon: AppIcons.send,
        onPressed: () => _openSendSheet(context),
      ),
      const SizedBox(height: 16),
      Text('ACTIVITY',
          style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
              letterSpacing: 0.7)),
      const SizedBox(height: 8),
      if (_txs.isEmpty)
        AppCard(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No transactions yet — send test sats to the address above.',
                  style: AppText.bodyMuted, textAlign: TextAlign.center),
            ),
          ),
        )
      else
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              for (final tx in _txs) _TxRow(tx: tx),
            ],
          ),
        ),
    ];
  }

  void _openSendSheet(BuildContext context) {
    final addressCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 24, 20, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send Signet BTC', style: AppText.detailTitle),
            const SizedBox(height: 16),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(
                  labelText: 'Signet address', hintText: 'tb1...'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Amount (sats)', hintText: '1000'),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Broadcast',
              onPressed: () async {
                final amount = int.tryParse(amountCtrl.text.trim());
                final address = addressCtrl.text.trim();
                if (amount == null || amount <= 0 || address.isEmpty) return;
                Navigator.of(ctx).pop();
                try {
                  final txid = await _service.send(address: address, amountSat: amount);
                  if (!mounted) return;
                  await showAppModal(context,
                      icon: AppIcons.check,
                      iconColor: AppColors.gain,
                      title: 'Broadcast',
                      message: 'Transaction sent: $txid');
                  await _refresh();
                } catch (e) {
                  if (!mounted) return;
                  await showAppModal(context,
                      icon: AppIcons.close,
                      iconColor: AppColors.loss,
                      title: 'Send failed',
                      message: e.toString());
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionDetailsView {
  const TransactionDetailsView(
      {required this.txid, required this.netSat, required this.confirmed});
  final String txid;
  final BigInt netSat;
  final bool confirmed;
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx});
  final TransactionDetailsView tx;

  @override
  Widget build(BuildContext context) {
    final incoming = tx.netSat >= BigInt.zero;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: (incoming ? AppColors.gain : AppColors.loss).withOpacity(0.13),
                shape: BoxShape.circle),
            child: Icon(
                incoming ? AppIcons.receive : AppIcons.send,
                size: 15,
                color: incoming ? AppColors.gain : AppColors.loss),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tx.txid.substring(0, 10)}…',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(tx.confirmed ? 'Confirmed' : 'Pending',
                    style: TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          Text('${incoming ? '+' : ''}${tx.netSat} sats',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: incoming ? AppColors.gain : AppColors.loss)),
        ],
      ),
    );
  }
}

class _EmptyWalletCard extends StatelessWidget {
  const _EmptyWalletCard({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Icon(AppIcons.bitcoin, size: 36, color: AppColors.accent),
          const SizedBox(height: 12),
          Text('No Signet wallet yet', style: AppText.detailTitle),
          const SizedBox(height: 6),
          Text(
            'Creates a real BIP84 wallet on Bitcoin Signet (test network). '
            'No real funds are ever at risk.',
            textAlign: TextAlign.center,
            style: AppText.bodyMuted,
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Create Signet wallet', onPressed: onCreate),
        ],
      ),
    );
  }
}

class _BackupPhraseCard extends StatelessWidget {
  const _BackupPhraseCard({required this.phrase, required this.onDismiss});
  final String phrase;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.accentSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.bitcoin, size: 16, color: AppColors.accent),
              const SizedBox(width: 7),
              Text('Your backup phrase', style: AppText.cardTitle),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Testnet only, but treat it like the real thing — write it down. '
            'It will not be shown again.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
            child: Text(phrase,
                style: TextStyle(
                    fontSize: 13, fontFamily: 'monospace', color: AppColors.textPrimary)),
          ),
          const SizedBox(height: 10),
          SecondaryButton(label: "I've saved it", onPressed: onDismiss),
        ],
      ),
    );
  }
}

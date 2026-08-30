import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/choice_chip.dart';
import '../../../state/models/demo_account.dart';
import '../../../state/providers/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../shared/pin_confirm_screen.dart';
import '../shared/processing_screen.dart';
import '../shared/result_screen.dart';

/// Step 3 — amount entry, with a live balance check and a currency
/// selector when the user holds more than one balance. Continuing
/// pushes the shared PIN → Processing → Result steps.
class SendAmountScreen extends ConsumerStatefulWidget {
  const SendAmountScreen({super.key, required this.account});

  final DemoAccount account;

  @override
  ConsumerState<SendAmountScreen> createState() => _SendAmountScreenState();
}

class _SendAmountScreenState extends ConsumerState<SendAmountScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _currency = 'NGN';

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final balance = state.fiatBalances[_currency] ?? 0;
    final canContinue = _amount > 0 && _amount <= balance;

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(AppIcons.chevronLeft,
                          color: AppColors.textPrimary)),
                  const SizedBox(width: 4),
                  Text('To ${widget.account.displayName}',
                      style: AppText.pageTitle.copyWith(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 22),
              if (state.fiatBalances.length > 1) ...[
                const Text('Currency', style: AppText.sectionTitle),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final code in state.fiatBalances.keys)
                      AppChoiceChip(
                          label: code,
                          selected: code == _currency,
                          onTap: () => setState(() => _currency = code)),
                  ],
                ),
                const SizedBox(height: 22),
              ],
              const Text('Amount', style: AppText.sectionTitle),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                onChanged: (_) => setState(() {}),
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13.5),
                decoration:
                    InputDecoration(hintText: '0.00', suffixText: _currency),
              ),
              const SizedBox(height: 6),
              Text('Available: ${balance.toStringAsFixed(2)} $_currency',
                  style: AppText.caption),
              const SizedBox(height: 22),
              const Text('Note (optional)', style: AppText.sectionTitle),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13.5),
                decoration:
                    const InputDecoration(hintText: 'What is this for?'),
              ),
              if (_amount > balance) ...[
                const SizedBox(height: 10),
                const Text('Amount exceeds your available balance.',
                    style: TextStyle(
                        color: AppColors.loss,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ],
              const Spacer(),
              PrimaryButton(
                  label: 'Continue', onPressed: canContinue ? _continue : null),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    final confirmed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => PinConfirmScreen(
          title: 'Confirm PIN',
          subtitle:
              'Enter your PIN to send ${_amount.toStringAsFixed(2)} $_currency'),
    ));
    if (confirmed != true || !mounted) return;

    final amount = _amount;
    final currency = _currency;
    final note = _noteController.text.trim();
    final notifier = ref.read(appStateProvider.notifier);

    final success = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => ProcessingScreen<bool>(
        steps: const ['Sending money…'],
        task: () => notifier.sendInternal(
            toUsername: widget.account.username,
            toDisplayName: widget.account.displayName,
            currency: currency,
            amount: amount,
            note: note.isEmpty ? null : note),
      ),
    ));
    if (!mounted) return;

    if (success == true) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResultScreen(
          success: true,
          headline: 'Money sent',
          lines: [
            ResultLine('Recipient', widget.account.displayName),
            ResultLine('Amount', '${amount.toStringAsFixed(2)} $currency'),
            ResultLine('Time', TimeOfDay.now().format(context)),
          ],
          primaryLabel: 'Done',
          onPrimary: () => Navigator.of(context).popUntil((r) => r.isFirst),
          secondaryLabel: 'Send another',
          onSecondary: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ));
    } else {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResultScreen(
          success: false,
          headline: 'Send failed',
          detailMessage: 'Insufficient balance — nothing was sent.',
          lines: const [],
          primaryLabel: 'Try again',
          onPrimary: () => Navigator.of(context).pop(),
        ),
      ));
    }
  }
}

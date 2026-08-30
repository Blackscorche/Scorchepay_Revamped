import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_modal.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/detail_header.dart';
import '../../../core/widgets/device_photo_card.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../state/models/savings.dart';
import '../../../state/providers/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class SavingsGoalDetailScreen extends ConsumerStatefulWidget {
  const SavingsGoalDetailScreen({super.key, required this.goalId});

  final String goalId;

  @override
  ConsumerState<SavingsGoalDetailScreen> createState() =>
      _SavingsGoalDetailScreenState();
}

class _SavingsGoalDetailScreenState
    extends ConsumerState<SavingsGoalDetailScreen> {
  File? _coverPhoto;

  void _addMoney(SavingsGoal goal) {
    final amtCtrl = TextEditingController();
    showAppSheet(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Up "${goal.name}"', style: AppText.detailTitle),
          const SizedBox(height: 14),
          TextField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount to add',
              hintText: '0.00',
              prefixText: '${goal.currency} ',
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Confirm Deposit',
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text.trim()) ?? 0;
              if (amt > 0) {
                await ref
                    .read(appStateProvider.notifier)
                    .contributeSavings(goal.id, amt);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  showAppModal(
                    context,
                    icon: AppIcons.check,
                    iconColor: AppColors.gain,
                    title: 'Deposit Successful',
                    message:
                        'Added ${amt.toStringAsFixed(2)} ${goal.currency} to "${goal.name}".',
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _withdraw(SavingsGoal goal) {
    final amtCtrl = TextEditingController();
    showAppSheet(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Withdraw from "${goal.name}"', style: AppText.detailTitle),
          if (goal.type == SavingsType.locked) ...[
            const SizedBox(height: 10),
            AppCard(
              color: AppColors.warn.withOpacity(0.12),
              padding: const EdgeInsets.all(12),
              child: const Text(
                'This is a Locked goal. Early withdrawal before maturity forfeits 30% of accrued interest.',
                style: TextStyle(
                    fontSize: 11.5, color: AppColors.warn, height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount to withdraw',
              hintText: '0.00',
              prefixText: '${goal.currency} ',
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Withdraw to Wallet',
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text.trim()) ?? 0;
              if (amt > 0) {
                await ref
                    .read(appStateProvider.notifier)
                    .withdrawSavings(goal.id, amt);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  showAppModal(
                    context,
                    icon: AppIcons.check,
                    iconColor: AppColors.gain,
                    title: 'Withdrawal Complete',
                    message:
                        'Moved ${amt.toStringAsFixed(2)} ${goal.currency} from "${goal.name}" to your spendable balance.',
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(savingsGoalsProvider);
    final match = goals.where((g) => g.id == widget.goalId);
    if (match.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                IconCircleButton(
                    icon: AppIcons.chevronLeft,
                    onTap: () => Navigator.of(context).pop()),
                const SizedBox(height: 40),
                const Text('Goal not found', style: AppText.cardTitle),
              ],
            ),
          ),
        ),
      );
    }
    final goal = match.first;

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            DetailHeader(
              icon: AppIcons.target,
              title: goal.name,
              subtitle: '${goal.currency} · ${goal.type.name.toUpperCase()}',
            ),
            const SizedBox(height: 20),
            DevicePhotoCard(
              label: 'Goal Cover Photo (Camera / Gallery)',
              photo: _coverPhoto,
              onChanged: (file) => setState(() => _coverPhoto = file),
              title: 'Pick Goal Photo',
              hint: 'Personalize with a photo of your goal (Car, House, Trip)',
              height: 130,
            ),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Saved',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '${goal.current.toStringAsFixed(2)} ${goal.currency}',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      if (goal.target != null)
                        StatusBadge(
                          label: '${(goal.progress * 100).toInt()}% Done',
                          tone: BadgeTone.good,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppProgressBar(value: goal.progress),
                  const SizedBox(height: 12),
                  if (goal.target != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target: ${goal.target!.toStringAsFixed(2)} ${goal.currency}',
                            style: AppText.caption),
                        Text(
                            'Left: ${(goal.target! - goal.current).clamp(0, double.infinity).toStringAsFixed(2)} ${goal.currency}',
                            style: AppText.caption),
                      ],
                    ),
                  if (goal.apy != null) ...[
                    const Divider(color: AppColors.hairline, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Annual Percentage Yield (APY)',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        Text('${(goal.apy! * 100).toInt()}% APY',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.gain)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Add Money',
                    icon: AppIcons.plus,
                    onPressed: () => _addMoney(goal),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(
                    label: 'Withdraw',
                    icon: AppIcons.minus,
                    onPressed: () => _withdraw(goal),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

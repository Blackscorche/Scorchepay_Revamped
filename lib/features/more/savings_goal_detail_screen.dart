import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/detail_header.dart';
import '../../core/widgets/device_photo_card.dart';
import '../../core/widgets/progress_bar.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Detail + contribute/withdraw actions for one savings goal with custom device photo cover.
class SavingsGoalDetailScreen extends StatefulWidget {
  const SavingsGoalDetailScreen({super.key, required this.goal});

  final SavingsGoal goal;

  @override
  State<SavingsGoalDetailScreen> createState() =>
      _SavingsGoalDetailScreenState();
}

class _SavingsGoalDetailScreenState extends State<SavingsGoalDetailScreen> {
  File? _coverPhoto;
  late double _progress = widget.goal.progress;
  late String _saved = widget.goal.saved;

  void _addMoney(BuildContext context) {
    final amtCtrl = TextEditingController();
    showAppSheet(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Up "${widget.goal.name}"', style: AppText.detailTitle),
          const SizedBox(height: 14),
          TextField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount to add', hintText: '0.00', prefixText: '₦ '),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Confirm Deposit',
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text.trim()) ?? 0;
              if (amt > 0) {
                setState(() {
                  _progress = (_progress + 0.1).clamp(0.0, 1.0);
                });
                Navigator.of(ctx).pop();
                showAppModal(
                  context,
                  icon: AppIcons.check,
                  iconColor: AppColors.gain,
                  title: 'Added to Goal',
                  message: '₦${amt.toStringAsFixed(2)} added to "${widget.goal.name}".',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _withdraw(BuildContext context) {
    final amtCtrl = TextEditingController();
    showAppSheet(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Withdraw from "${widget.goal.name}"', style: AppText.detailTitle),
          const SizedBox(height: 14),
          TextField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount to withdraw', hintText: '0.00', prefixText: '₦ '),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Withdraw to Wallet',
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text.trim()) ?? 0;
              if (amt > 0) {
                Navigator.of(ctx).pop();
                showAppModal(
                  context,
                  icon: AppIcons.check,
                  iconColor: AppColors.gain,
                  title: 'Withdrawn',
                  message: '₦${amt.toStringAsFixed(2)} moved to your wallet balance.',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _deleteGoal(BuildContext context) {
    showAppModal(
      context,
      icon: AppIcons.trash,
      title: 'Goal deleted',
      message:
          '"${widget.goal.name}" has been deleted and its balance returned to your wallet.',
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
              icon: widget.goal.icon,
              title: widget.goal.name,
              subtitle: widget.goal.tag,
            ),
            const SizedBox(height: 20),
            DevicePhotoCard(
              label: 'Goal Cover Photo (Camera / Gallery)',
              photo: _coverPhoto,
              onChanged: (file) => setState(() => _coverPhoto = file),
              title: 'Personalize Goal Cover',
              hint: 'Snap or pick a picture of what you are saving for',
              height: 130,
            ),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppProgressBar(value: _progress),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$_saved saved',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      Text(
                        '${(_progress * 100).round()}% of ${widget.goal.target}',
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Add money',
                    icon: AppIcons.plus,
                    onPressed: () => _addMoney(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(
                    label: 'Withdraw',
                    icon: AppIcons.minus,
                    onPressed: () => _withdraw(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Delete goal',
              icon: AppIcons.trash,
              destructive: true,
              onPressed: () => _deleteGoal(context),
            ),
          ],
        ),
      ),
    );
  }
}

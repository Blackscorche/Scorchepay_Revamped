import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/detail_header.dart';
import '../../core/widgets/device_photo_card.dart';
import '../../core/widgets/progress_bar.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class GroupGoalDetailScreen extends StatefulWidget {
  const GroupGoalDetailScreen({
    super.key,
    required this.name,
    required this.memberLabels,
    required this.savedLabel,
    required this.progress,
    required this.progressColor,
  });

  final String name;
  final List<String> memberLabels;
  final String savedLabel;
  final double progress;
  final Color progressColor;

  @override
  State<GroupGoalDetailScreen> createState() => _GroupGoalDetailScreenState();
}

class _GroupGoalDetailScreenState extends State<GroupGoalDetailScreen> {
  File? _groupPhoto;
  late double _progress = widget.progress;

  void _contribute(BuildContext context) {
    final amtCtrl = TextEditingController();
    showAppSheet(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contribute to "${widget.name}"', style: AppText.detailTitle),
          const SizedBox(height: 14),
          TextField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Contribution Amount', hintText: '0.00', prefixText: '₦ '),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Submit Contribution',
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text.trim()) ?? 0;
              if (amt > 0) {
                setState(() => _progress = (_progress + 0.08).clamp(0.0, 1.0));
                Navigator.of(ctx).pop();
                showAppModal(
                  context,
                  icon: AppIcons.check,
                  iconColor: AppColors.gain,
                  title: 'Contribution Recorded',
                  message: '₦${amt.toStringAsFixed(2)} added to "${widget.name}".',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _invite(BuildContext context) {
    final userCtrl = TextEditingController();
    showAppSheet(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invite Members to "${widget.name}"', style: AppText.detailTitle),
          const SizedBox(height: 14),
          TextField(
            controller: userCtrl,
            decoration: const InputDecoration(labelText: 'Username, phone or email', hintText: '@username'),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Send Invites',
            onPressed: () {
              if (userCtrl.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop();
                showAppModal(
                  context,
                  icon: AppIcons.check,
                  title: 'Invitations Dispatched',
                  message: 'Invited ${userCtrl.text.trim()} to contribute to "${widget.name}".',
                );
              }
            },
          ),
        ],
      ),
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
              icon: AppIcons.users,
              title: widget.name,
              subtitle: '${widget.memberLabels.length} participating members',
            ),
            const SizedBox(height: 20),
            DevicePhotoCard(
              label: 'Group Photo / Project Banner (Camera / Gallery)',
              photo: _groupPhoto,
              onChanged: (file) => setState(() => _groupPhoto = file),
              title: 'Upload Group Photo',
              hint: 'Take a photo of squad, family or project goal',
              height: 130,
            ),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final m in widget.memberLabels) _MemberChip(label: m),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppProgressBar(value: _progress, color: widget.progressColor),
                  const SizedBox(height: 10),
                  Text(widget.savedLabel,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Contribute',
                    icon: AppIcons.plus,
                    onPressed: () => _contribute(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(
                    label: 'Invite members',
                    icon: AppIcons.users,
                    onPressed: () => _invite(context),
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

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: AppColors.surface2, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

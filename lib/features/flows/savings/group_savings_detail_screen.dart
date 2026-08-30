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

class GroupSavingsDetailScreen extends ConsumerStatefulWidget {
  const GroupSavingsDetailScreen({super.key, required this.goalId});

  final String goalId;

  @override
  ConsumerState<GroupSavingsDetailScreen> createState() =>
      _GroupSavingsDetailScreenState();
}

class _GroupSavingsDetailScreenState
    extends ConsumerState<GroupSavingsDetailScreen> {
  File? _groupCoverPhoto;

  Future<void> _contribute(SavingsGoal goal) async {
    final amt = goal.groupContributionAmount ?? 50000;
    await ref
        .read(appStateProvider.notifier)
        .groupContribute(goal.id, '@scorche', bySimulated: false);
    if (!mounted) return;
    showAppModal(
      context,
      icon: AppIcons.check,
      iconColor: AppColors.gain,
      title: 'Contribution Recorded',
      message:
          'Paid ₦${amt.toStringAsFixed(2)} for this cycle into "${goal.name}".',
    );
  }

  void _invite(SavingsGoal goal) {
    final userCtrl = TextEditingController();
    showAppSheet(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Invite Member', style: AppText.detailTitle),
          const SizedBox(height: 12),
          TextField(
            controller: userCtrl,
            decoration: const InputDecoration(
                labelText: 'Username or email', hintText: '@username'),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Send Invitation',
            onPressed: () {
              if (userCtrl.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop();
                showAppModal(
                  context,
                  icon: AppIcons.check,
                  title: 'Invitation Sent',
                  message:
                      'Invited ${userCtrl.text.trim()} to join "${goal.name}".',
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
    final goals = ref.watch(savingsGoalsProvider);
    final match = goals.where((g) => g.id == widget.goalId);
    final goal = match.isNotEmpty
        ? match.first
        : SavingsGoal(
            id: widget.goalId,
            name: 'Family House Fund',
            type: SavingsType.group,
            currency: 'NGN',
            current: 2160000,
            target: 4000000,
            groupContributionAmount: 50000,
            groupMembers: [
              GroupMember(username: '@scorche', displayName: 'You (Host)', hasContributedThisCycle: true),
              GroupMember(username: '@ada_b', displayName: 'Ada Balogun', hasContributedThisCycle: true),
              GroupMember(username: '@chidi.eth', displayName: 'Chidi Eze', hasContributedThisCycle: true),
              GroupMember(username: '@nomsa', displayName: 'Nomsa Khumalo', hasContributedThisCycle: false),
            ],
          );

    final members = goal.groupMembers ?? [];

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            DetailHeader(
              icon: AppIcons.users,
              title: goal.name,
              subtitle: 'Rotating Group Savings (Ajo / Esusu)',
            ),
            const SizedBox(height: 20),
            DevicePhotoCard(
              label: 'Group Banner / Cover Photo (Camera / Gallery)',
              photo: _groupCoverPhoto,
              onChanged: (file) => setState(() => _groupCoverPhoto = file),
              title: 'Upload Group Photo',
              hint: 'Take a photo of members, family or project',
              height: 130,
            ),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Pool',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '${goal.current.toStringAsFixed(2)} ${goal.currency}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      StatusBadge(
                        label: '${members.length} Members',
                        tone: BadgeTone.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppProgressBar(value: goal.progress),
                  const SizedBox(height: 10),
                  Text(
                    'Cycle Contribution: ₦${(goal.groupContributionAmount ?? 50000).toStringAsFixed(2)} / member',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Pay Contribution',
                    icon: AppIcons.check,
                    onPressed: () => _contribute(goal),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(
                    label: 'Invite Member',
                    icon: AppIcons.plus,
                    onPressed: () => _invite(goal),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Member Roster & Payout Rotation',
                style: AppText.sectionTitle),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
              child: Column(
                children: [
                  for (int i = 0; i < members.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(members[i].displayName,
                                    style: AppText.body
                                        .copyWith(fontWeight: FontWeight.w700)),
                                Text(members[i].username,
                                    style: AppText.caption),
                              ],
                            ),
                          ),
                          StatusBadge(
                            label: members[i].hasContributedThisCycle
                                ? 'Paid'
                                : 'Pending',
                            tone: members[i].hasContributedThisCycle
                                ? BadgeTone.good
                                : BadgeTone.warn,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

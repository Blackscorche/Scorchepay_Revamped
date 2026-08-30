import 'package:flutter/material.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../state/models/savings.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'goal_setup_screen.dart';

class _TypeInfo {
  const _TypeInfo(this.type, this.icon, this.title, this.rule);
  final SavingsType type;
  final IconData icon;
  final String title;
  final String rule;
}

const _types = [
  _TypeInfo(SavingsType.goal, AppIcons.target, 'Goal savings', 'Any target, any date — withdraw any time, no penalty.'),
  _TypeInfo(SavingsType.locked, AppIcons.lock, 'Locked savings', 'Higher rate, but a penalty applies if you withdraw before maturity.'),
  _TypeInfo(SavingsType.emergency, AppIcons.shield, 'Emergency fund', 'Low-friction, instant access — built for the unexpected.'),
  _TypeInfo(SavingsType.roundUp, AppIcons.repeat, 'Round-up savings', 'Every purchase rounds up to the nearest unit — the difference is swept in.'),
  _TypeInfo(SavingsType.autoSaveFixed, AppIcons.calendar, 'Auto-save (fixed)', 'A fixed amount saved automatically on a schedule you choose.'),
  _TypeInfo(SavingsType.autoSavePercent, AppIcons.chartBar, 'Auto-save (% of income)', 'A percentage of every qualifying deposit is saved automatically.'),
  _TypeInfo(SavingsType.scheduled, AppIcons.calendar, 'Scheduled savings', 'Save a fixed amount on specific calendar dates.'),
  _TypeInfo(SavingsType.group, AppIcons.users, 'Group savings', 'Rotating contributions — everyone pays in, one member is paid out each cycle.'),
  _TypeInfo(SavingsType.stablecoin, AppIcons.coins, 'Stablecoin savings', 'Earn yield in USDT — not NDIC-insured like a naira bank deposit.'),
];

/// Step 1 — choose a savings type before setup, each with its
/// funding/withdrawal rule stated up front (spec §13) so the user can
/// tell Locked from Emergency from Round-up before committing.
class GoalTypePickerScreen extends StatelessWidget {
  const GoalTypePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Row(
              children: [
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(AppIcons.chevronLeft, color: AppColors.textPrimary)),
                const SizedBox(width: 4),
                const Text('New savings goal', style: AppText.pageTitle),
              ],
            ),
            const SizedBox(height: 6),
            Text('What kind of savings is this?', style: AppText.bodyMuted),
            const SizedBox(height: 18),
            for (final t in _types)
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GoalSetupScreen(type: t.type))),
                behavior: HitTestBehavior.opaque,
                child: AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
                        child: Icon(t.icon, size: 18, color: AppColors.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.title, style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(t.rule, style: AppText.caption),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(AppIcons.chevronRight, size: 16, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

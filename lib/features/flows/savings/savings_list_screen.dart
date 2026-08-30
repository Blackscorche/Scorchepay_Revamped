import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../state/models/savings.dart';
import '../../../state/providers/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'goal_type_picker_screen.dart';
import 'group_savings_detail_screen.dart';
import 'savings_goal_detail_screen.dart';

/// Real savings list bound to live state — replaces the static goal
/// cards that used to live in book_detail_screen.dart.
class SavingsListScreen extends ConsumerWidget {
  const SavingsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingsGoalsProvider);
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
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(AppIcons.chevronLeft, color: AppColors.textPrimary)),
                  const SizedBox(width: 4),
                  const Text('Savings', style: AppText.pageTitle),
                ],
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'New savings goal',
                icon: AppIcons.plus,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalTypePickerScreen())),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: goals.isEmpty
                    ? Center(child: Text('No savings goals yet — start one to see it here.', style: AppText.bodyMuted, textAlign: TextAlign.center))
                    : ListView.builder(
                        itemCount: goals.length,
                        itemBuilder: (context, i) {
                          final g = goals[i];
                          return GestureDetector(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => g.type == SavingsType.group ? GroupSavingsDetailScreen(goalId: g.id) : SavingsGoalDetailScreen(goalId: g.id),
                            )),
                            behavior: HitTestBehavior.opaque,
                            child: AppCard(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(g.name, style: AppText.body.copyWith(fontWeight: FontWeight.w700))),
                                      Text(_typeLabel(g.type), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
                                    ],
                                  ),
                                  const SizedBox(height: 9),
                                  AppProgressBar(value: g.progress),
                                  const SizedBox(height: 9),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${g.current.toStringAsFixed(2)} ${g.currency} saved', style: AppText.caption),
                                      if (g.target != null) Text('of ${g.target!.toStringAsFixed(2)} ${g.currency}', style: AppText.caption),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(SavingsType t) {
    switch (t) {
      case SavingsType.goal:
        return 'GOAL';
      case SavingsType.locked:
        return 'LOCKED';
      case SavingsType.emergency:
        return 'EMERGENCY';
      case SavingsType.roundUp:
        return 'ROUND-UP';
      case SavingsType.autoSaveFixed:
        return 'AUTO-SAVE';
      case SavingsType.autoSavePercent:
        return 'AUTO %';
      case SavingsType.scheduled:
        return 'SCHEDULED';
      case SavingsType.group:
        return 'GROUP';
      case SavingsType.stablecoin:
        return 'STABLECOIN';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/choice_chip.dart';
import '../../../state/models/demo_account.dart';
import '../../../state/models/savings.dart';
import '../../../state/providers/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'group_savings_detail_screen.dart';
import 'savings_goal_detail_screen.dart';

const _uuid = Uuid();

/// Step 2 — goal setup, with fields that change based on [type]: lock
/// duration + penalty disclosure for Locked, round-up unit for
/// Round-up, percent + minimum threshold for Auto-save-percent, member
/// picker + contribution + payout order for Group.
class GoalSetupScreen extends ConsumerStatefulWidget {
  const GoalSetupScreen({super.key, required this.type});

  final SavingsType type;

  @override
  ConsumerState<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends ConsumerState<GoalSetupScreen> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  String _currency = 'NGN';
  int _lockDays = 30;
  double _roundUpUnit = 100;
  double _autoSavePercent = 10;
  final _autoSaveAmountController = TextEditingController();
  final Set<DemoAccount> _members = {};
  final _groupContributionController = TextEditingController();

  static const _lockOptions = [30, 60, 90, 180];
  static const _roundUpOptions = [100.0, 500.0, 1000.0];

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _autoSaveAmountController.dispose();
    _groupContributionController.dispose();
    super.dispose();
  }

  bool get _canCreate {
    if (_nameController.text.trim().isEmpty) return false;
    if (widget.type == SavingsType.group) {
      return _members.isNotEmpty && (double.tryParse(_groupContributionController.text.trim()) ?? 0) > 0;
    }
    if (widget.type == SavingsType.autoSaveFixed) {
      return (double.tryParse(_autoSaveAmountController.text.trim()) ?? 0) > 0;
    }
    return (double.tryParse(_targetController.text.trim()) ?? 0) > 0 || widget.type == SavingsType.roundUp || widget.type == SavingsType.autoSavePercent;
  }

  Future<void> _create() async {
    final notifier = ref.read(appStateProvider.notifier);
    final id = _uuid.v4();

    if (widget.type == SavingsType.group) {
      final members = [
        GroupMember(username: '@scorche', displayName: 'You'),
        for (final a in _members) GroupMember(username: a.username, displayName: a.displayName),
      ];
      final goal = SavingsGoal(
        id: id,
        name: _nameController.text.trim(),
        type: SavingsType.group,
        currency: _currency,
        groupMembers: members,
        groupContributionAmount: double.tryParse(_groupContributionController.text.trim()) ?? 0,
      );
      await notifier.createSavingsGoal(goal);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GroupSavingsDetailScreen(goalId: id)));
      return;
    }

    final goal = SavingsGoal(
      id: id,
      name: _nameController.text.trim(),
      type: widget.type,
      currency: _currency,
      target: double.tryParse(_targetController.text.trim()),
      lockUntil: widget.type == SavingsType.locked ? DateTime.now().add(Duration(days: _lockDays)) : null,
      penaltyPct: widget.type == SavingsType.locked ? 0.3 : null,
      apy: widget.type == SavingsType.locked || widget.type == SavingsType.stablecoin ? 0.12 : null,
      roundUpUnit: widget.type == SavingsType.roundUp ? _roundUpUnit : null,
      autoSaveAmount: widget.type == SavingsType.autoSaveFixed ? double.tryParse(_autoSaveAmountController.text.trim()) : null,
      autoSavePercent: widget.type == SavingsType.autoSavePercent ? _autoSavePercent : null,
    );
    await notifier.createSavingsGoal(goal);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SavingsGoalDetailScreen(goalId: id)));
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text('Set up goal', style: AppText.pageTitle),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    const Text('Goal name', style: AppText.sectionTitle),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                      decoration: const InputDecoration(hintText: 'e.g. New laptop'),
                    ),
                    const SizedBox(height: 22),
                    const Text('Currency', style: AppText.sectionTitle),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final c in ['NGN', 'USD', 'GHS', 'USDT'])
                          AppChoiceChip(label: c, selected: c == _currency, onTap: () => setState(() => _currency = c)),
                      ],
                    ),
                    if (widget.type == SavingsType.group) ..._groupFields() else ...[
                      if (widget.type != SavingsType.autoSaveFixed) ...[
                        const SizedBox(height: 22),
                        const Text('Target amount', style: AppText.sectionTitle),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _targetController,
                          onChanged: (_) => setState(() {}),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                          decoration: const InputDecoration(hintText: '0.00'),
                        ),
                      ],
                      ..._typeSpecificFields(),
                    ],
                  ],
                ),
              ),
              PrimaryButton(label: 'Create goal', onPressed: _canCreate ? _create : null),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _typeSpecificFields() {
    switch (widget.type) {
      case SavingsType.locked:
        return [
          const SizedBox(height: 22),
          const Text('Lock duration', style: AppText.sectionTitle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [for (final d in _lockOptions) AppChoiceChip(label: '$d days', selected: d == _lockDays, onTap: () => setState(() => _lockDays = d))],
          ),
          const SizedBox(height: 14),
          AppCard(
            color: AppColors.warn.withOpacity(0.1),
            padding: const EdgeInsets.all(14),
            child: const Text(
              '12% APY while locked. Withdrawing before maturity forfeits 30% of accrued interest — this is disclosed now so it\'s never a surprise at withdrawal.',
              style: TextStyle(fontSize: 11.5, color: AppColors.warn, height: 1.4),
            ),
          ),
        ];
      case SavingsType.roundUp:
        return [
          const SizedBox(height: 22),
          const Text('Round up to the nearest', style: AppText.sectionTitle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final u in _roundUpOptions)
                AppChoiceChip(label: '₦${u.toStringAsFixed(0)}', selected: u == _roundUpUnit, onTap: () => setState(() => _roundUpUnit = u)),
            ],
          ),
        ];
      case SavingsType.autoSaveFixed:
        return [
          const SizedBox(height: 22),
          const Text('Amount per run', style: AppText.sectionTitle),
          const SizedBox(height: 10),
          TextField(
            controller: _autoSaveAmountController,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
            decoration: const InputDecoration(hintText: '0.00'),
          ),
          const SizedBox(height: 8),
          Text('Set the schedule from Automation once this goal is created.', style: AppText.caption),
        ];
      case SavingsType.autoSavePercent:
        return [
          const SizedBox(height: 22),
          Text('Save ${_autoSavePercent.toStringAsFixed(0)}% of every deposit', style: AppText.sectionTitle),
          Slider(
            value: _autoSavePercent,
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: AppColors.accent,
            onChanged: (v) => setState(() => _autoSavePercent = v),
          ),
        ];
      case SavingsType.stablecoin:
        return [
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: const Text(
              '12% APY, accrued daily. Funded in USDT. Not NDIC-insured the way a naira bank deposit is.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ];
      default:
        return const [];
    }
  }

  List<Widget> _groupFields() {
    return [
      const SizedBox(height: 22),
      const Text('Contribution per member, per cycle', style: AppText.sectionTitle),
      const SizedBox(height: 10),
      TextField(
        controller: _groupContributionController,
        onChanged: (_) => setState(() {}),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
        decoration: const InputDecoration(hintText: '0.00'),
      ),
      const SizedBox(height: 22),
      const Text('Invite members', style: AppText.sectionTitle),
      const SizedBox(height: 4),
      Text('Payout order follows the order you select them in — you always go first.', style: AppText.caption),
      const SizedBox(height: 10),
      for (final a in DemoAccounts.all)
        GestureDetector(
          onTap: () => setState(() => _members.contains(a) ? _members.remove(a) : _members.add(a)),
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _members.contains(a) ? AppColors.accentSoft : AppColors.surface2,
              border: Border.all(color: _members.contains(a) ? AppColors.accent.withOpacity(0.5) : AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(child: Text('${a.displayName}  ${a.username}', style: AppText.body)),
                if (_members.contains(a)) const Icon(AppIcons.check, size: 16, color: AppColors.accent),
              ],
            ),
          ),
        ),
    ];
  }
}

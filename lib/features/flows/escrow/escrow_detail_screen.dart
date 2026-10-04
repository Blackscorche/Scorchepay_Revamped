import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../state/models/escrow.dart';
import '../../../state/providers/providers.dart';
import '../../../state/services/smart_pay_engine.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../shared/pin_confirm_screen.dart';
import '../shared/processing_screen.dart';
import '../shared/result_screen.dart';
import '../smart_pay/funding_breakdown_screen.dart';
import 'dispute_resolution_screen.dart';
import 'raise_dispute_screen.dart';
import 'submit_evidence_screen.dart';

/// The centerpiece screen — every escrow state (draft, awaiting funding,
/// funded with per-milestone progress, disputed, completed) renders
/// here with role-appropriate real actions, the full timeline (spec
/// §10's "chronological history... with timestamps and actor"), and —
/// for whichever side isn't the local user — the "Simulate: {name}
/// does X" affordances so both roles are testable solo.
class EscrowDetailScreen extends ConsumerStatefulWidget {
  const EscrowDetailScreen({super.key, required this.escrowId});

  final String escrowId;

  @override
  ConsumerState<EscrowDetailScreen> createState() => _EscrowDetailScreenState();
}

class _EscrowDetailScreenState extends ConsumerState<EscrowDetailScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  EscrowContract? _find(List<EscrowContract> all) {
    for (final e in all) {
      if (e.id == widget.escrowId) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final escrows = ref.watch(escrowsProvider);
    final e = _find(escrows);
    if (e == null) {
      return Scaffold(
          backgroundColor: AppColors.page,
          body: Center(
              child: Text('Escrow not found', style: AppText.bodyMuted)));
    }

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            Row(
              children: [
                IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(AppIcons.chevronLeft,
                        color: AppColors.textPrimary)),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(e.description,
                        style: AppText.pageTitle.copyWith(fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status',
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.textSecondary)),
                      StatusBadge(
                          label: _statusLabel(e.status),
                          tone: _statusTone(e.status)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _row('Counterparty',
                      '${e.counterpartyName} (${e.counterpartyUsername})'),
                  _row('Your role', e.isBuyer ? 'Buyer' : 'Seller'),
                  _row('Total', '₦${e.totalAmount.toStringAsFixed(2)}'),
                  _row('Fee', '₦${e.fee.toStringAsFixed(2)}'),
                  _row('Protection', 'Funds held until both sides confirm'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ..._stateActions(context, e),
            if (e.status == EscrowStatus.funded ||
                e.status == EscrowStatus.disputed) ...[
              const SizedBox(height: 8),
              Text('Milestones', style: AppText.sectionTitle),
              const SizedBox(height: 10),
              for (final m in e.milestones) _milestoneCard(context, e, m),
            ],
            const SizedBox(height: 22),
            Text('Timeline', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  for (int i = 0; i < e.timeline.length; i++)
                    _timelineRow(e.timeline[i],
                        last: i == e.timeline.length - 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _stateActions(BuildContext context, EscrowContract e) {
    switch (e.status) {
      case EscrowStatus.draft:
        return [
          _waitingCard(
              'Waiting for ${e.counterpartyName} to accept the terms.'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: SecondaryButton(
                      label: 'Simulate: reject',
                      onPressed: () => _respond(e, false))),
              const SizedBox(width: 9),
              Expanded(
                  child: PrimaryButton(
                      label: 'Simulate: accept',
                      onPressed: () => _respond(e, true))),
            ],
          ),
        ];
      case EscrowStatus.awaitingFunding:
        if (e.isBuyer) {
          return [
            PrimaryButton(
                label: 'Fund escrow',
                icon: AppIcons.shield,
                onPressed: () => _fund(context, e))
          ];
        }
        return [
          _waitingCard(
              'Waiting for ${e.counterpartyName} to fund this escrow.'),
          const SizedBox(height: 10),
          PrimaryButton(
              label: 'Simulate: ${e.counterpartyName} funds',
              onPressed: () => ref
                  .read(appStateProvider.notifier)
                  .simulateCounterpartyFundEscrow(e.id)),
        ];
      case EscrowStatus.cancelled:
        return [
          _waitingCard(
              '${e.counterpartyName} rejected these terms — this escrow is cancelled.')
        ];
      default:
        return [];
    }
  }

  Widget _milestoneCard(
      BuildContext context, EscrowContract e, EscrowMilestone m) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(m.description, style: AppText.body)),
              Text('₦${m.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          StatusBadge(
              label: _milestoneLabel(m.status), tone: _milestoneTone(m.status)),
          const SizedBox(height: 10),
          ..._milestoneActions(context, e, m),
        ],
      ),
    );
  }

  List<Widget> _milestoneActions(
      BuildContext context, EscrowContract e, EscrowMilestone m) {
    switch (m.status) {
      case MilestoneStatus.pending:
      case MilestoneStatus.inProgress:
        if (!e.isBuyer) {
          return [
            SecondaryButton(
              label: 'Submit evidence',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      SubmitEvidenceScreen(escrowId: e.id, milestoneId: m.id))),
            ),
          ];
        }
        return [
          Text('Waiting for ${e.counterpartyName} to deliver.',
              style: AppText.caption)
        ];
      case MilestoneStatus.evidenceSubmitted:
        final remaining = m.reviewDeadline == null
            ? Duration.zero
            : m.reviewDeadline!.difference(DateTime.now());
        final label = remaining.isNegative
            ? 'Releasing…'
            : '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')} left to review';
        if (m.evidenceNote != null) {
          return [
            Text('Evidence: "${m.evidenceNote}"', style: AppText.caption),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warn)),
            const SizedBox(height: 10),
            if (e.isBuyer)
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Raise dispute',
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => RaiseDisputeScreen(
                                  escrowId: e.id, milestoneId: m.id))),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                      child: PrimaryButton(
                          label: 'Release',
                          onPressed: () => _confirmRelease(context, e, m))),
                ],
              )
            else
              Text('Waiting for ${e.isBuyer ? 'you' : 'the buyer'} to review.',
                  style: AppText.caption),
          ];
        }
        return const [];
      case MilestoneStatus.disputed:
        return [
          PrimaryButton(
            label: 'View dispute',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => DisputeResolutionScreen(
                    escrowId: e.id, milestoneId: m.id))),
          ),
        ];
      case MilestoneStatus.released:
        return [
          const Text('Released',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gain))
        ];
      case MilestoneStatus.reviewWindow:
        return const [];
    }
  }

  Future<void> _respond(EscrowContract e, bool accept) async {
    await ref
        .read(appStateProvider.notifier)
        .respondToEscrow(e.id, accept: accept);
  }

  Future<void> _fund(BuildContext context, EscrowContract e) async {
    final notifier = ref.read(appStateProvider.notifier);
    final plan = notifier.planPayment(
        nativeCurrency: e.currency, nativeAmount: e.totalAmount);
    final proceed = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) =>
            FundingBreakdownScreen(plan: plan, payLabel: 'Fund escrow')));
    if (proceed != true || !context.mounted) return;

    final confirmed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => PinConfirmScreen(
          title: 'Confirm PIN',
          subtitle:
              'Enter your PIN to fund ₦${e.totalAmount.toStringAsFixed(2)} into escrow'),
    ));
    if (confirmed != true || !context.mounted) return;

    final result = await Navigator.of(context).push<SmartPayResult>(MaterialPageRoute(
      builder: (_) => ProcessingScreen<SmartPayResult>(
          steps: const ['Moving funds into escrow…'],
          task: () => notifier.fundEscrow(e.id)),
    ));
    if (!context.mounted) return;
    final failed = result == null || !result.isSuccess;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultScreen(
        success: !failed,
        headline: failed ? 'Funding failed' : 'Escrow funded',
        detailMessage: failed
            ? (result?.outcome == SmartPayOutcome.insufficientFunds
                ? 'Insufficient balance — nothing was moved into escrow.'
                : 'Something went wrong — nothing was moved into escrow.')
            : null,
        lines: failed
            ? const []
            : [
                ResultLine('Amount', '₦${e.totalAmount.toStringAsFixed(2)}'),
                ResultLine('Held until', 'Release or dispute resolution')
              ],
        primaryLabel: failed ? 'Try again' : 'Done',
        onPrimary: () => Navigator.of(context).pop(),
      ),
    ));
  }

  Future<void> _confirmRelease(
      BuildContext context, EscrowContract e, EscrowMilestone m) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Release funds?', style: AppText.detailTitle),
            const SizedBox(height: 8),
            Text(
                '₦${m.amount.toStringAsFixed(2)} will be released to ${e.counterpartyName} immediately. This cannot be undone.',
                style: AppText.bodyMuted),
            const SizedBox(height: 20),
            PrimaryButton(
                label: 'Release ₦${m.amount.toStringAsFixed(2)}',
                onPressed: () => Navigator.of(ctx).pop(true)),
            const SizedBox(height: 10),
            SecondaryButton(
                label: 'Cancel', onPressed: () => Navigator.of(ctx).pop(false)),
          ],
        ),
      ),
    );
    if (ok == true) {
      await ref
          .read(appStateProvider.notifier)
          .releaseEscrowMilestone(e.id, m.id);
    }
  }

  Widget _waitingCard(String text) {
    return AppCard(
      color: AppColors.accentSoft,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(AppIcons.bell, size: 16, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _timelineRow(EscrowTimelineEvent ev, {required bool last}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: AppColors.accent, shape: BoxShape.circle)),
              if (!last)
                Container(width: 1.5, height: 30, color: AppColors.hairline),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ev.description,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('${ev.actor} · ${_timeAgo(ev.at)}',
                    style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary)),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary))),
        ],
      ),
    );
  }

  String _timeAgo(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _statusLabel(EscrowStatus s) {
    switch (s) {
      case EscrowStatus.draft:
        return 'Draft';
      case EscrowStatus.awaitingFunding:
        return 'Awaiting funding';
      case EscrowStatus.funded:
        return 'Active';
      case EscrowStatus.disputed:
        return 'Dispute';
      case EscrowStatus.completed:
        return 'Done';
      case EscrowStatus.refunded:
        return 'Refunded';
      case EscrowStatus.cancelled:
        return 'Cancelled';
    }
  }

  BadgeTone _statusTone(EscrowStatus s) {
    switch (s) {
      case EscrowStatus.funded:
        return BadgeTone.good;
      case EscrowStatus.awaitingFunding:
      case EscrowStatus.draft:
        return BadgeTone.warn;
      case EscrowStatus.disputed:
        return BadgeTone.crit;
      default:
        return BadgeTone.neutral;
    }
  }

  String _milestoneLabel(MilestoneStatus s) {
    switch (s) {
      case MilestoneStatus.pending:
        return 'Pending';
      case MilestoneStatus.inProgress:
        return 'In progress';
      case MilestoneStatus.evidenceSubmitted:
        return 'In review';
      case MilestoneStatus.reviewWindow:
        return 'In review';
      case MilestoneStatus.released:
        return 'Released';
      case MilestoneStatus.disputed:
        return 'Disputed';
    }
  }

  BadgeTone _milestoneTone(MilestoneStatus s) {
    switch (s) {
      case MilestoneStatus.released:
        return BadgeTone.good;
      case MilestoneStatus.evidenceSubmitted:
      case MilestoneStatus.reviewWindow:
        return BadgeTone.warn;
      case MilestoneStatus.disputed:
        return BadgeTone.crit;
      default:
        return BadgeTone.neutral;
    }
  }
}

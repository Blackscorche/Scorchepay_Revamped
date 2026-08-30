import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../../state/models/escrow.dart';
import '../../../state/providers/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'escrow_detail_screen.dart';

/// Simulated ScorchePay arbitration — stands in for a real ops team.
/// Shows both sides' evidence and lets the local user (playing the
/// arbitrator) pick the outcome, exactly as spec §10 describes the
/// resolution options: full release, full refund, or a split.
class DisputeResolutionScreen extends ConsumerWidget {
  const DisputeResolutionScreen(
      {super.key, required this.escrowId, required this.milestoneId});

  final String escrowId;
  final String milestoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final escrows = ref.watch(escrowsProvider);
    EscrowContract? e;
    EscrowMilestone? m;
    for (final x in escrows) {
      if (x.id == escrowId) {
        e = x;
        for (final mm in x.milestones) {
          if (mm.id == milestoneId) m = mm;
        }
      }
    }
    if (e == null || m == null) {
      return const Scaffold(
          backgroundColor: AppColors.page,
          body: Center(
              child: Text('Dispute not found', style: AppText.bodyMuted)));
    }
    final escrow = e;
    final milestone = m;

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
                    icon: const Icon(AppIcons.chevronLeft,
                        color: AppColors.textPrimary)),
                const SizedBox(width: 4),
                const Expanded(
                    child: Text('Dispute review', style: AppText.pageTitle)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Standing in for ScorchePay support in this demo.',
                style: AppText.bodyMuted),
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Buyer\'s claim',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.loss)),
                  const SizedBox(height: 6),
                  Text(milestone.disputeReason ?? 'No reason provided',
                      style: AppText.body),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Seller\'s evidence',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gain)),
                  const SizedBox(height: 6),
                  Text(
                      milestone.evidenceNote ??
                          'Seller submitted no evidence before the dispute.',
                      style: AppText.body),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('Resolution', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Release in full to ${escrow.counterpartyName}',
              onPressed: () => _resolve(context, ref, escrow.id, milestone.id,
                  DisputeResolution.releaseToSeller),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Refund in full to buyer',
              onPressed: () => _resolve(context, ref, escrow.id, milestone.id,
                  DisputeResolution.refundToBuyer),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Split 50/50',
              onPressed: () => _resolve(context, ref, escrow.id, milestone.id,
                  DisputeResolution.split),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref, String escrowId,
      String milestoneId, DisputeResolution resolution) async {
    final confirmed = await showModalBottomSheet<bool>(
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
            const Text('Confirm resolution', style: AppText.detailTitle),
            const SizedBox(height: 8),
            const Text('This action is final and cannot be undone.',
                style: AppText.bodyMuted),
            const SizedBox(height: 20),
            PrimaryButton(
                label: 'Confirm', onPressed: () => Navigator.of(ctx).pop(true)),
            const SizedBox(height: 10),
            SecondaryButton(
                label: 'Cancel', onPressed: () => Navigator.of(ctx).pop(false)),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(appStateProvider.notifier)
        .resolveEscrowDispute(escrowId, milestoneId, resolution);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => EscrowDetailScreen(escrowId: escrowId)));
  }
}

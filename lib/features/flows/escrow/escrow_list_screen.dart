import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/list_row.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../state/models/escrow.dart';
import '../../../state/providers/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'create_escrow_screen.dart';
import 'escrow_detail_screen.dart';

/// Real escrow list bound to live state — replaces the static 4-row
/// mock list that used to live in book_detail_screen.dart.
class EscrowListScreen extends ConsumerWidget {
  const EscrowListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final escrows = ref.watch(escrowsProvider);
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
                      icon: Icon(AppIcons.chevronLeft,
                          color: AppColors.textPrimary)),
                  const SizedBox(width: 4),
                  Text('Escrow', style: AppText.pageTitle),
                ],
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Create new escrow',
                icon: AppIcons.plus,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CreateEscrowScreen())),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: escrows.isEmpty
                    ? Center(
                        child: Text(
                            'No escrow deals yet — create one to protect a transaction.',
                            style: AppText.bodyMuted,
                            textAlign: TextAlign.center),
                      )
                    : ListView.builder(
                        itemCount: escrows.length,
                        itemBuilder: (context, i) {
                          final e = escrows[i];
                          return AppListRow(
                            icon: AppIcons.shield,
                            title: e.description,
                            subtitle:
                                '${e.counterpartyName} · ${e.escrowType} · ${e.isBuyer ? 'You are buying' : 'You are selling'}',
                            trailing: StatusBadge(
                                label: _statusLabel(e.status),
                                tone: _statusTone(e.status)),
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        EscrowDetailScreen(escrowId: e.id))),
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
      case EscrowStatus.completed:
        return BadgeTone.neutral;
      case EscrowStatus.refunded:
      case EscrowStatus.cancelled:
        return BadgeTone.neutral;
    }
  }
}

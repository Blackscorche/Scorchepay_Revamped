import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/choice_chip.dart';
import '../../../core/widgets/device_photo_card.dart';
import '../../../core/widgets/detail_header.dart';
import '../../../state/providers/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

const _reasons = [
  'Item never arrived',
  'Not as described',
  'Wrong item / damaged',
  'Seller unresponsive',
  'Counterfeit goods',
  'Other'
];

/// Buyer raises a dispute on a milestone — reason + description + photo evidence from device.
class RaiseDisputeScreen extends ConsumerStatefulWidget {
  const RaiseDisputeScreen(
      {super.key, required this.escrowId, required this.milestoneId});

  final String escrowId;
  final String milestoneId;

  @override
  ConsumerState<RaiseDisputeScreen> createState() => _RaiseDisputeScreenState();
}

class _RaiseDisputeScreenState extends ConsumerState<RaiseDisputeScreen> {
  String _reason = _reasons.first;
  final _descController = TextEditingController();
  File? _evidencePhoto;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final full = '$_reason — ${_descController.text.trim()}';
    await ref
        .read(appStateProvider.notifier)
        .raiseEscrowDispute(widget.escrowId, widget.milestoneId, full);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _descController.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            const DetailHeader(
              icon: AppIcons.shield,
              title: 'Raise a Dispute',
              subtitle: 'Freeze funds and submit claim with photo evidence to arbitration',
            ),
            const SizedBox(height: 20),
            const Text('Dispute Reason', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in _reasons)
                  AppChoiceChip(
                    label: r,
                    selected: r == _reason,
                    onTap: () => setState(() => _reason = r),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            const Text('Describe What Happened', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              onChanged: (_) => setState(() {}),
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
              decoration: const InputDecoration(
                hintText: 'Provide complete details regarding the condition, tracking status or communication with the seller...',
              ),
            ),
            const SizedBox(height: 22),
            DevicePhotoCard(
              label: 'Photo Evidence (Camera / Library)',
              photo: _evidencePhoto,
              onChanged: (file) => setState(() => _evidencePhoto = file),
              title: 'Attach Dispute Proof',
              hint: 'Take a photo of damaged item, wrong parcel or chat proof',
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Submit Dispute to Arbitration',
              destructive: true,
              onPressed: canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}

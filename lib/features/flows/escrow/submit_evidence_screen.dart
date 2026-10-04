import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/photo_picker_sheet.dart';
import '../../../state/providers/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Seller submits proof of delivery/completion — a real photo picked
/// from the device camera or library, plus a tracking number/delivery
/// note. Submitting genuinely starts the buyer's review window
/// countdown on the detail screen.
class SubmitEvidenceScreen extends ConsumerStatefulWidget {
  const SubmitEvidenceScreen({super.key, required this.escrowId, required this.milestoneId});

  final String escrowId;
  final String milestoneId;

  @override
  ConsumerState<SubmitEvidenceScreen> createState() => _SubmitEvidenceScreenState();
}

class _SubmitEvidenceScreenState extends ConsumerState<SubmitEvidenceScreen> {
  final _noteController = TextEditingController();
  File? _photo;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await showPhotoPickerSheet(context, title: 'Delivery photo', hasPhoto: _photo != null);
    if (result == null || !mounted) return;
    setState(() => _photo = result.removed ? null : result.file);
  }

  Future<void> _submit() async {
    await ref.read(appStateProvider.notifier).submitEscrowEvidence(widget.escrowId, widget.milestoneId, _noteController.text.trim());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _noteController.text.trim().isNotEmpty;
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
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(AppIcons.chevronLeft, color: AppColors.textPrimary)),
                  const SizedBox(width: 4),
                  Text('Submit evidence', style: AppText.pageTitle),
                ],
              ),
              const SizedBox(height: 18),
              Text('Tracking number / delivery note', style: AppText.sectionTitle),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                onChanged: (_) => setState(() {}),
                maxLines: 4,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                decoration: const InputDecoration(hintText: 'e.g. GIG Logistics tracking GIG-3391-NG, delivered to front desk'),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _pickPhoto,
                child: _photo == null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(AppIcons.camera, size: 18, color: AppColors.muted),
                            const SizedBox(width: 10),
                            Text('Attach a photo (optional)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          children: [
                            Image.file(_photo!, width: double.infinity, height: 160, fit: BoxFit.cover),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(20)),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(AppIcons.check, size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Attached · tap to change', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const Spacer(),
              PrimaryButton(label: 'Submit evidence', onPressed: canSubmit ? _submit : null),
            ],
          ),
        ),
      ),
    );
  }
}

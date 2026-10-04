import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/detail_header.dart';
import '../../core/widgets/status_badge.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'create_flow_screen.dart';

/// Detail + actions for one escrow deal — reached by tapping a row on
/// the Escrow book. Actions offered depend on the deal's status.
class EscrowDetailScreen extends StatelessWidget {
  const EscrowDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusTone,
    required this.counterparty,
    required this.amount,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final BadgeTone statusTone;
  final String counterparty;
  final String amount;

  void _release(BuildContext context) {
    showAppModal(
      context,
      icon: AppIcons.check,
      iconColor: AppColors.gain,
      title: 'Funds released',
      message: '$amount released to $counterparty. This escrow is now closed.',
    );
  }

  void _message(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreateFlowScreen(
        icon: AppIcons.user,
        title: 'Message $counterparty',
        subtitle: 'Send a message about this escrow',
        fields: const [
          CreateField.text(
              label: 'Message', hint: 'Type your message', multiline: true)
        ],
        submitLabel: 'Send message',
        successTitle: 'Message sent',
        successMessage: (v) => 'Sent to $counterparty: "${v[0]}"',
      ),
    ));
  }

  void _dispute(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreateFlowScreen(
        icon: AppIcons.shield,
        title: 'Open Escrow Dispute',
        subtitle: 'Explain the issue and attach photo evidence from your device',
        fields: const [
          CreateField.chips(
              label: 'Dispute Reason',
              chips: ['Item damaged', 'Not as described', 'Never delivered', 'Wrong parcel']),
          CreateField.text(
              label: 'Describe what happened',
              hint: 'Provide full details',
              multiline: true),
          CreateField.photo(
              label: 'Attach Photo Evidence (Camera / Gallery)',
              hint: 'Take a photo of damaged item or receipt'),
        ],
        submitLabel: 'Submit Dispute to Support',
        successTitle: 'Dispute Submitted',
        successMessage: (v) =>
            'Support has been notified and dispute registered for "${v[0]}".',
      ),
    ));
  }

  void _uploadProof(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreateFlowScreen(
        icon: AppIcons.package,
        title: 'Upload Delivery Proof',
        subtitle: 'Add delivery photos and tracking information',
        fields: const [
          CreateField.text(
              label: 'Courier / Tracking Number',
              hint: 'e.g. GIGL-9842109 or Waybill ID'),
          CreateField.photo(
              label: 'Delivery Photo / Waybill Receipt (Device Photo)',
              hint: 'Snap parcel photo with courier stamp'),
          CreateField.text(
              label: 'Delivery Notes (Optional)',
              hint: 'e.g. Handed to security at reception',
              isOptional: true),
        ],
        submitLabel: 'Submit Proof of Delivery',
        successTitle: 'Proof Submitted',
        successMessage: (v) =>
            'Delivery proof for "${v[0]}" submitted. Awaiting buyer inspection confirmation.',
      ),
    ));
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
                icon: AppIcons.shield, title: title, subtitle: subtitle),
            const SizedBox(height: 22),
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
                      StatusBadge(label: statusLabel, tone: statusTone),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _row('Counterparty', counterparty),
                  _row('Amount', amount),
                  _row('Protection', 'Funds held until both sides confirm'),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (statusLabel == 'Dispute') ...[
              PrimaryButton(
                  label: 'Contact support', onPressed: () => _dispute(context)),
              const SizedBox(height: 10),
              SecondaryButton(
                  label: 'Message counterparty',
                  onPressed: () => _message(context)),
            ] else if (statusLabel == 'Pending') ...[
              PrimaryButton(
                  label: 'Upload delivery proof',
                  onPressed: () => _uploadProof(context)),
              const SizedBox(height: 10),
              SecondaryButton(
                  label: 'Message counterparty',
                  onPressed: () => _message(context)),
            ] else if (statusLabel == 'Done') ...[
              SecondaryButton(
                  label: 'Message counterparty',
                  onPressed: () => _message(context)),
            ] else ...[
              PrimaryButton(
                  label: 'Release funds', onPressed: () => _release(context)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: SecondaryButton(
                          label: 'Message',
                          onPressed: () => _message(context))),
                  const SizedBox(width: 9),
                  Expanded(
                      child: SecondaryButton(
                          label: 'Open dispute',
                          onPressed: () => _dispute(context))),
                ],
              ),
            ],
          ],
        ),
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
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

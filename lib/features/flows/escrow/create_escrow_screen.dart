import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/choice_chip.dart';
import '../../../core/widgets/device_photo_card.dart';
import '../../../state/models/demo_account.dart';
import '../../../state/models/escrow.dart';
import '../../../state/providers/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'escrow_detail_screen.dart';

const _escrowTypes = [
  'Marketplace',
  'Freelance',
  'Business',
  'Property',
  'Vehicle',
  'Digital goods',
  'Physical goods'
];

/// Create Escrow — stepped wizard with device photo attachment support.
class CreateEscrowScreen extends ConsumerStatefulWidget {
  const CreateEscrowScreen({super.key});

  @override
  ConsumerState<CreateEscrowScreen> createState() => _CreateEscrowScreenState();
}

class _CreateEscrowScreenState extends ConsumerState<CreateEscrowScreen> {
  int _step = 0;
  String _type = _escrowTypes.first;
  DemoAccount? _counterparty;
  EscrowRole _role = EscrowRole.buyer;
  final _descController = TextEditingController();
  File? _itemPhoto;
  bool _multiMilestone = false;
  final _singleAmountController = TextEditingController();
  final List<(TextEditingController, TextEditingController)>
      _milestoneControllers = [
    (TextEditingController(), TextEditingController()),
  ];
  String _inspectionPeriod = '48 hours';

  @override
  void dispose() {
    _descController.dispose();
    _singleAmountController.dispose();
    for (final (d, a) in _milestoneControllers) {
      d.dispose();
      a.dispose();
    }
    super.dispose();
  }

  double get _total {
    if (!_multiMilestone) {
      return double.tryParse(_singleAmountController.text.trim()) ?? 0;
    }
    return _milestoneControllers.fold<double>(
        0, (sum, c) => sum + (double.tryParse(c.$2.text.trim()) ?? 0));
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return true;
      case 1:
        return _counterparty != null;
      case 2:
        return _descController.text.trim().isNotEmpty &&
            (!_multiMilestone ? _total > 0 : true);
      case 3:
        return !_multiMilestone ||
            (_milestoneControllers.every((c) =>
                c.$1.text.trim().isNotEmpty &&
                (double.tryParse(c.$2.text.trim()) ?? 0) > 0));
      default:
        return true;
    }
  }

  void _next() {
    if (_step == 2 && !_multiMilestone) {
      setState(() => _step = 4);
      return;
    }
    setState(() => _step += 1);
  }

  void _back() {
    if (_step == 4 && !_multiMilestone) {
      setState(() => _step = 2);
      return;
    }
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step -= 1);
  }

  Future<void> _create() async {
    final milestones = _multiMilestone
        ? [
            for (final (d, a) in _milestoneControllers)
              EscrowMilestone(
                  id: DateTime.now().microsecondsSinceEpoch.toString() + d.text,
                  description: d.text.trim(),
                  amount: double.tryParse(a.text.trim()) ?? 0),
          ]
        : [
            EscrowMilestone(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                description: _descController.text.trim(),
                amount: _total)
          ];

    final id = await ref.read(appStateProvider.notifier).createEscrow(
          escrowType: _type,
          counterpartyUsername: _counterparty!.username,
          counterpartyName: _counterparty!.displayName,
          role: _role,
          description: _descController.text.trim(),
          currency: 'NGN',
          milestones: milestones,
        );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => EscrowDetailScreen(escrowId: id)));
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
                  IconButton(
                      onPressed: _back,
                      icon: const Icon(AppIcons.chevronLeft,
                          color: AppColors.textPrimary)),
                  const SizedBox(width: 4),
                  const Text('New Escrow', style: AppText.pageTitle),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                  value: (_step + 1) / 5,
                  backgroundColor: AppColors.surface2,
                  color: AppColors.accent,
                  minHeight: 3),
              const SizedBox(height: 20),
              Expanded(child: SingleChildScrollView(child: _buildStep())),
              PrimaryButton(
                  label: _step == 4 ? 'Create escrow' : 'Continue',
                  onPressed:
                      _canContinue ? (_step == 4 ? _create : _next) : null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _typeStep();
      case 1:
        return _counterpartyStep();
      case 2:
        return _detailsStep();
      case 3:
        return _milestonesStep();
      default:
        return _reviewStep();
    }
  }

  Widget _typeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What kind of escrow is this?', style: AppText.sectionTitle),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in _escrowTypes)
              AppChoiceChip(
                  label: t,
                  selected: t == _type,
                  onTap: () => setState(() => _type = t))
          ],
        ),
      ],
    );
  }

  Widget _counterpartyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Who is the other party?', style: AppText.sectionTitle),
        const SizedBox(height: 10),
        for (final a in DemoAccounts.all)
          GestureDetector(
            onTap: () => setState(() => _counterparty = a),
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _counterparty == a
                    ? AppColors.accentSoft
                    : AppColors.surface2,
                border: Border.all(
                    color: _counterparty == a
                        ? AppColors.accent.withOpacity(0.5)
                        : AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: a.displayName, style: AppText.body),
                      TextSpan(
                          text: '  ${a.username}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11.5)),
                    ])),
                  ),
                  if (_counterparty == a)
                    const Icon(AppIcons.check,
                        size: 16, color: AppColors.accent),
                ],
              ),
            ),
          ),
        const SizedBox(height: 22),
        const Text('Your role', style: AppText.sectionTitle),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppChoiceChip(
                    label: "I'm the buyer",
                    selected: _role == EscrowRole.buyer,
                    onTap: () => setState(() => _role = EscrowRole.buyer))),
            const SizedBox(width: 8),
            Expanded(
                child: AppChoiceChip(
                    label: "I'm the seller",
                    selected: _role == EscrowRole.seller,
                    onTap: () => setState(() => _role = EscrowRole.seller))),
          ],
        ),
      ],
    );
  }

  Widget _detailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Description', style: AppText.sectionTitle),
        const SizedBox(height: 10),
        TextField(
          controller: _descController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
          decoration:
              const InputDecoration(hintText: 'e.g. iPhone 16 Pro, 256GB Desert Titanium'),
        ),
        const SizedBox(height: 22),
        DevicePhotoCard(
          label: 'Item / Contract Photo (Camera / Library)',
          photo: _itemPhoto,
          onChanged: (f) => setState(() => _itemPhoto = f),
          title: 'Upload Item Photo',
          hint: 'Take a photo of product, agreement or asset',
        ),
        const SizedBox(height: 22),
        const Text('Inspection Period', style: AppText.sectionTitle),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (final p in ['24 hours', '48 hours', '3 days', '7 days'])
              AppChoiceChip(
                label: p,
                selected: _inspectionPeriod == p,
                onTap: () => setState(() => _inspectionPeriod = p),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Multiple milestones', style: AppText.sectionTitle),
            Switch(
              value: _multiMilestone,
              activeThumbColor: AppColors.accent,
              onChanged: (v) => setState(() => _multiMilestone = v),
            ),
          ],
        ),
        if (!_multiMilestone) ...[
          const SizedBox(height: 10),
          const Text('Amount', style: AppText.sectionTitle),
          const SizedBox(height: 10),
          TextField(
            controller: _singleAmountController,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
            decoration:
                const InputDecoration(hintText: '0.00', prefixText: '₦ '),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
                'You will define each milestone and its amount on the next step.',
                style: AppText.caption),
          ),
      ],
    );
  }

  Widget _milestonesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Milestones', style: AppText.sectionTitle),
        const SizedBox(height: 10),
        for (int i = 0; i < _milestoneControllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Milestone ${i + 1}',
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary)),
                      if (_milestoneControllers.length > 1)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _milestoneControllers.removeAt(i)),
                          child: const Icon(AppIcons.trash,
                              size: 16, color: AppColors.loss),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _milestoneControllers[i].$1,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                        hintText: 'Milestone description (e.g. 50% deposit)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _milestoneControllers[i].$2,
                    onChanged: (_) => setState(() {}),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                        hintText: '0.00', prefixText: '₦ '),
                  ),
                ],
              ),
            ),
          ),
        SecondaryButton(
          label: 'Add milestone',
          icon: AppIcons.plus,
          onPressed: () => setState(() => _milestoneControllers
              .add((TextEditingController(), TextEditingController()))),
        ),
      ],
    );
  }

  Widget _reviewStep() {
    const feePct = 0.01;
    final fee = _total * feePct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review', style: AppText.sectionTitle),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Type', _type),
              _row('Counterparty',
                  '${_counterparty?.displayName} (${_counterparty?.username})'),
              _row('Your role', _role == EscrowRole.buyer ? 'Buyer' : 'Seller'),
              _row('Description', _descController.text.trim()),
              _row('Inspection period', _inspectionPeriod),
              _row('Total amount', '₦${_total.toStringAsFixed(2)}'),
              _row('Escrow fee (1%)', '₦${fee.toStringAsFixed(2)}'),
            ],
          ),
        ),
        if (_itemPhoto != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(_itemPhoto!, height: 120, width: double.infinity, fit: BoxFit.cover),
          ),
        ],
        const SizedBox(height: 14),
        AppCard(
          color: AppColors.accentSoft,
          padding: const EdgeInsets.all(14),
          child: Text(
            _role == EscrowRole.buyer
                ? 'Since this is a demo, ${_counterparty?.displayName}\'s acceptance and delivery are simulated from the escrow detail screen — you\'ll fund it yourself as the buyer.'
                : 'Since this is a demo, ${_counterparty?.displayName}\'s acceptance and funding as buyer are simulated from the escrow detail screen — you\'ll submit delivery evidence as the seller.',
            style: const TextStyle(
                fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary)),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

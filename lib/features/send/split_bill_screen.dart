import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/detail_header.dart';
import '../../core/widgets/device_photo_card.dart';
import '../../state/models/demo_account.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SplitBillScreen extends StatefulWidget {
  const SplitBillScreen({super.key});

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController(text: 'Restaurant Dinner');
  File? _receiptPhoto;
  double _tipPercentage = 10;
  final Set<String> _selectedFriends = {'@ada_b', '@chidi.eth'};

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  double get _subtotal => double.tryParse(_amountController.text.trim()) ?? 0;
  double get _tipAmount => _subtotal * (_tipPercentage / 100);
  double get _totalBill => _subtotal + _tipAmount;
  int get _totalPeople => _selectedFriends.length + 1; // Includes user
  double get _perPersonShare => _totalPeople > 0 ? _totalBill / _totalPeople : 0;

  bool get _canSplit => _subtotal > 0;

  void _sendRequests() {
    showAppModal(
      context,
      icon: AppIcons.check,
      iconColor: AppColors.gain,
      title: 'Split Requests Sent!',
      message:
          'Requested ₦${_perPersonShare.toStringAsFixed(2)} each from ${_selectedFriends.length} friends for "${_descController.text.trim()}". Receipt photo attached.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            const DetailHeader(
              icon: AppIcons.package,
              title: 'Split Bill',
              subtitle: 'Snap a receipt photo, calculate shares and request money',
            ),
            const SizedBox(height: 20),
            DevicePhotoCard(
              label: '1. Photograph Physical Bill (Camera / Library)',
              photo: _receiptPhoto,
              onChanged: (file) => setState(() => _receiptPhoto = file),
              title: 'Snap Bill Receipt',
              hint: 'Take a photo of restaurant or grocery receipt',
            ),
            const SizedBox(height: 22),
            const Text('2. Bill Details', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Title / Place', hintText: 'e.g. Dinner at RSVP'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Bill Total (Before Tip)',
                hintText: '0.00',
                prefixText: '₦ ',
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('3. Tip / Service Charge', style: AppText.sectionTitle),
                Text('${_tipPercentage.toInt()}% (₦${_tipAmount.toStringAsFixed(2)})', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent)),
              ],
            ),
            Slider(
              value: _tipPercentage,
              min: 0,
              max: 25,
              divisions: 5,
              activeColor: AppColors.accent,
              onChanged: (v) => setState(() => _tipPercentage = v),
            ),
            const SizedBox(height: 18),
            const Text('4. Split With Friends', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in DemoAccounts.all)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedFriends.contains(a.username)) {
                          _selectedFriends.remove(a.username);
                        } else {
                          _selectedFriends.add(a.username);
                        }
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedFriends.contains(a.username) ? AppColors.accentSoft : AppColors.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedFriends.contains(a.username) ? AppColors.accent : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(a.displayName, style: AppText.body.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Text('(${a.username})', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          if (_selectedFriends.contains(a.username)) ...[
                            const SizedBox(width: 6),
                            const Icon(AppIcons.check, size: 14, color: AppColors.accent),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            AppCard(
              color: AppColors.accentSoft,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Bill (incl. tip)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text('₦${_totalBill.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    ],
                  ),
                  const Divider(color: AppColors.hairline, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Each person pays ($_totalPeople people)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text('₦${_perPersonShare.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.accent)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Request ₦${_perPersonShare.toStringAsFixed(2)} from each friend',
              onPressed: _canSplit ? _sendRequests : null,
            ),
          ],
        ),
      ),
    );
  }
}

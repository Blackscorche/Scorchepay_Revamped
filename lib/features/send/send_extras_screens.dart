import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/choice_chip.dart';
import '../../core/widgets/detail_header.dart';
import '../../core/widgets/device_photo_card.dart';
import '../../core/widgets/list_row.dart';
import '../../core/widgets/status_badge.dart';
import '../../state/models/demo_account.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

// ==========================================
// 1. SCHEDULED PAYMENTS SCREEN
// ==========================================

class ScheduledPaymentItem {
  ScheduledPaymentItem({
    required this.id,
    required this.recipient,
    required this.amount,
    required this.currency,
    required this.scheduledDate,
    required this.category,
    this.note = '',
    this.isActive = true,
  });

  final String id;
  final String recipient;
  final double amount;
  final String currency;
  DateTime scheduledDate;
  final String category;
  final String note;
  bool isActive;
}

class ScheduledPaymentsScreen extends StatefulWidget {
  const ScheduledPaymentsScreen({super.key});

  @override
  State<ScheduledPaymentsScreen> createState() => _ScheduledPaymentsScreenState();
}

class _ScheduledPaymentsScreenState extends State<ScheduledPaymentsScreen> {
  final List<ScheduledPaymentItem> _items = [
    ScheduledPaymentItem(
      id: 'sch_1',
      recipient: '@designer_kay',
      amount: 45000,
      currency: 'NGN',
      scheduledDate: DateTime.now().add(const Duration(days: 3)),
      category: 'Design Freelance Milestone',
      note: 'Final design payment',
    ),
    ScheduledPaymentItem(
      id: 'sch_2',
      recipient: 'Ikeja Electric (04521199201)',
      amount: 15000,
      currency: 'NGN',
      scheduledDate: DateTime.now().add(const Duration(days: 7)),
      category: 'Electricity Bill',
      note: 'Auto monthly utility',
    ),
    ScheduledPaymentItem(
      id: 'sch_3',
      recipient: '@ada_b',
      amount: 25000,
      currency: 'NGN',
      scheduledDate: DateTime.now().add(const Duration(days: 14)),
      category: 'Shared Office Rent',
      note: 'Workspace contribution',
    ),
  ];

  void _createPayment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NewScheduledPaymentFlow(
          onCreated: (item) {
            setState(() => _items.insert(0, item));
          },
        ),
      ),
    );
  }

  void _cancelPayment(int index) {
    showAppSheet(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cancel Scheduled Payment', style: AppText.detailTitle),
          const SizedBox(height: 10),
          Text(
            'Are you sure you want to cancel the scheduled transfer of ₦${_items[index].amount.toStringAsFixed(2)} to ${_items[index].recipient}?',
            style: AppText.bodyMuted,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Cancel Payment',
            destructive: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _items.removeAt(index));
              showAppModal(
                context,
                icon: AppIcons.trash,
                title: 'Payment Cancelled',
                message: 'The scheduled payment has been removed.',
              );
            },
          ),
        ],
      ),
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
              icon: AppIcons.calendar,
              title: 'Scheduled Payments',
              subtitle: 'Set up payments to execute automatically on future dates',
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Schedule a new payment',
              icon: AppIcons.plus,
              onPressed: _createPayment,
            ),
            const SizedBox(height: 22),
            Text('Upcoming Scheduled Transfers', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            if (_items.isEmpty)
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                child: Column(
                  children: [
                    Icon(AppIcons.calendar, size: 36, color: AppColors.muted),
                    SizedBox(height: 12),
                    Text('No scheduled payments', style: AppText.cardTitle),
                    SizedBox(height: 4),
                    Text('Payments you schedule for future dates will appear here.', style: AppText.caption, textAlign: TextAlign.center),
                  ],
                ),
              )
            else
              AppCard(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
                child: Column(
                  children: [
                    for (int i = 0; i < _items.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.accentSoft,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(AppIcons.calendar, size: 18, color: AppColors.accent),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_items[i].recipient, style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_formatDate(_items[i].scheduledDate)} · ${_items[i].category}',
                                    style: AppText.caption,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₦${_items[i].amount.toStringAsFixed(2)}',
                                  style: AppText.tabular.copyWith(fontWeight: FontWeight.w800, fontSize: 13.5),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => _cancelPayment(i),
                                  child: const Text('Cancel', style: TextStyle(fontSize: 11, color: AppColors.loss, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _NewScheduledPaymentFlow extends StatefulWidget {
  const _NewScheduledPaymentFlow({required this.onCreated});

  final ValueChanged<ScheduledPaymentItem> onCreated;

  @override
  State<_NewScheduledPaymentFlow> createState() => _NewScheduledPaymentFlowState();
}

class _NewScheduledPaymentFlowState extends State<_NewScheduledPaymentFlow> {
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _pickedDate = DateTime.now().add(const Duration(days: 3));
  String _category = 'Transfer';
  File? _receiptAttachment;

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _recipientController.text.trim().isNotEmpty &&
      (double.tryParse(_amountController.text.trim()) ?? 0) > 0;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.accent,
              surface: AppColors.surface2,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _pickedDate = picked);
  }

  void _submit() {
    final item = ScheduledPaymentItem(
      id: 'sch_${DateTime.now().millisecondsSinceEpoch}',
      recipient: _recipientController.text.trim(),
      amount: double.tryParse(_amountController.text.trim()) ?? 0,
      currency: 'NGN',
      scheduledDate: _pickedDate,
      category: _category,
      note: _noteController.text.trim(),
    );
    widget.onCreated(item);
    Navigator.of(context).pop();
    showAppModal(
      context,
      icon: AppIcons.check,
      iconColor: AppColors.gain,
      title: 'Payment Scheduled',
      message: '₦${item.amount.toStringAsFixed(2)} is scheduled to be sent to ${item.recipient} on ${_formatDate(_pickedDate)}.',
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
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
              icon: AppIcons.calendar,
              title: 'Schedule a Payment',
              subtitle: 'Specify recipient, amount, date and optional attachment',
            ),
            const SizedBox(height: 22),
            Text('Recipient', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            TextField(
              controller: _recipientController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '@username, bank account or email',
                prefixIcon: Icon(AppIcons.user, size: 18, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (final a in DemoAccounts.all.take(3))
                  GestureDetector(
                    onTap: () => setState(() => _recipientController.text = a.username),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(a.username, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Text('Amount', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixText: '₦ ',
              ),
            ),
            const SizedBox(height: 22),
            Text('Execution Date', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _selectDate,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderStrong),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(AppIcons.calendar, size: 18, color: AppColors.accent),
                        const SizedBox(width: 10),
                        Text(_formatDate(_pickedDate), style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Text('Change date', style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text('Category', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in ['Transfer', 'Rent', 'Freelance', 'Subscription', 'Invoice', 'Family'])
                  AppChoiceChip(
                    label: c,
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            DevicePhotoCard(
              label: 'Attach Invoice / Receipt (Optional)',
              photo: _receiptAttachment,
              onChanged: (file) => setState(() => _receiptAttachment = file),
              title: 'Attach Document',
              hint: 'Take a photo or choose invoice from library',
            ),
            const SizedBox(height: 22),
            Text('Note for Recipient', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(hintText: 'e.g. October workspace fee'),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Schedule Payment',
              onPressed: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. RECURRING PAYMENTS SCREEN
// ==========================================

class RecurringPaymentRule {
  RecurringPaymentRule({
    required this.id,
    required this.recipient,
    required this.amount,
    required this.frequency,
    required this.nextRun,
    this.isActive = true,
  });

  final String id;
  final String recipient;
  final double amount;
  final String frequency;
  DateTime nextRun;
  bool isActive;
}

class RecurringPaymentsScreen extends StatefulWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  State<RecurringPaymentsScreen> createState() => _RecurringPaymentsScreenState();
}

class _RecurringPaymentsScreenState extends State<RecurringPaymentsScreen> {
  final List<RecurringPaymentRule> _rules = [
    RecurringPaymentRule(
      id: 'rec_1',
      recipient: 'MTN Internet Fibre',
      amount: 18000,
      frequency: 'Monthly (1st)',
      nextRun: DateTime.now().add(const Duration(days: 9)),
      isActive: true,
    ),
    RecurringPaymentRule(
      id: 'rec_2',
      recipient: '@nomsa (Allowance)',
      amount: 30000,
      frequency: 'Bi-weekly',
      nextRun: DateTime.now().add(const Duration(days: 4)),
      isActive: true,
    ),
    RecurringPaymentRule(
      id: 'rec_3',
      recipient: 'Gym Subscription',
      amount: 12500,
      frequency: 'Monthly',
      nextRun: DateTime.now().add(const Duration(days: 18)),
      isActive: false,
    ),
  ];

  void _addRule() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NewRecurringRuleFlow(
          onCreated: (rule) => setState(() => _rules.insert(0, rule)),
        ),
      ),
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
              icon: AppIcons.repeat,
              title: 'Recurring Payments',
              subtitle: 'Automate standing orders and repeating transfers',
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Set up recurring payment',
              icon: AppIcons.plus,
              onPressed: _addRule,
            ),
            const SizedBox(height: 22),
            Text('Active Standing Orders', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
              child: Column(
                children: [
                  for (int i = 0; i < _rules.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _rules[i].isActive ? AppColors.accentSoft : AppColors.surface3,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(AppIcons.repeat, size: 18, color: _rules[i].isActive ? AppColors.accent : AppColors.muted),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_rules[i].recipient, style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text('${_rules[i].frequency} · ₦${_rules[i].amount.toStringAsFixed(2)}', style: AppText.caption),
                              ],
                            ),
                          ),
                          Switch(
                            value: _rules[i].isActive,
                            activeThumbColor: AppColors.accent,
                            onChanged: (v) => setState(() => _rules[i].isActive = v),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewRecurringRuleFlow extends StatefulWidget {
  const _NewRecurringRuleFlow({required this.onCreated});

  final ValueChanged<RecurringPaymentRule> onCreated;

  @override
  State<_NewRecurringRuleFlow> createState() => _NewRecurringRuleFlowState();
}

class _NewRecurringRuleFlowState extends State<_NewRecurringRuleFlow> {
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  String _frequency = 'Weekly';

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _recipientController.text.trim().isNotEmpty &&
      (double.tryParse(_amountController.text.trim()) ?? 0) > 0;

  void _submit() {
    final rule = RecurringPaymentRule(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      recipient: _recipientController.text.trim(),
      amount: double.tryParse(_amountController.text.trim()) ?? 0,
      frequency: _frequency,
      nextRun: DateTime.now().add(const Duration(days: 7)),
    );
    widget.onCreated(rule);
    Navigator.of(context).pop();
    showAppModal(
      context,
      icon: AppIcons.check,
      iconColor: AppColors.gain,
      title: 'Recurring Payment Set',
      message: 'Automatic ${_frequency.toLowerCase()} transfer of ₦${rule.amount.toStringAsFixed(2)} to ${rule.recipient} has been scheduled.',
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
              icon: AppIcons.repeat,
              title: 'New Recurring Transfer',
              subtitle: 'Set frequency, recipient and amount',
            ),
            const SizedBox(height: 22),
            Text('Recipient', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            TextField(
              controller: _recipientController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: '@username or bank account'),
            ),
            const SizedBox(height: 22),
            Text('Amount per Interval', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '0.00', prefixText: '₦ '),
            ),
            const SizedBox(height: 22),
            Text('Frequency', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final f in ['Daily', 'Weekly', 'Bi-weekly', 'Monthly'])
                  AppChoiceChip(
                    label: f,
                    selected: _frequency == f,
                    onTap: () => setState(() => _frequency = f),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: 'Activate Standing Order', onPressed: _canSubmit ? _submit : null),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. PAYMENT REQUESTS SCREEN
// ==========================================

class PaymentRequestItem {
  PaymentRequestItem({
    required this.id,
    required this.counterparty,
    required this.amount,
    required this.note,
    required this.isIncoming,
    required this.date,
    this.photoAttachment,
    this.status = 'Pending',
  });

  final String id;
  final String counterparty;
  final double amount;
  final String note;
  final bool isIncoming;
  final DateTime date;
  final File? photoAttachment;
  String status;
}

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  int _tab = 0; // 0: Incoming, 1: Sent
  final List<PaymentRequestItem> _requests = [
    PaymentRequestItem(
      id: 'req_1',
      counterparty: '@ada_b',
      amount: 14500,
      note: 'Dinner at Cactus Restaurant',
      isIncoming: true,
      date: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    PaymentRequestItem(
      id: 'req_2',
      counterparty: '@chidi.eth',
      amount: 8000,
      note: 'Uber split to Lekki Phase 1',
      isIncoming: false,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PaymentRequestItem(
      id: 'req_3',
      counterparty: '@kwame_gh',
      amount: 22000,
      note: 'Movie tickets & popcorn',
      isIncoming: true,
      date: DateTime.now().subtract(const Duration(days: 2)),
      status: 'Paid',
    ),
  ];

  void _requestMoney() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NewRequestFlow(
          onCreated: (req) => setState(() => _requests.insert(0, req)),
        ),
      ),
    );
  }

  void _payRequest(PaymentRequestItem req) {
    showAppModal(
      context,
      icon: AppIcons.check,
      iconColor: AppColors.gain,
      title: 'Payment Sent',
      message: '₦${req.amount.toStringAsFixed(2)} paid to ${req.counterparty} for "${req.note}".',
    );
    setState(() => req.status = 'Paid');
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _requests.where((r) => _tab == 0 ? r.isIncoming : !r.isIncoming).toList();

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            const DetailHeader(
              icon: AppIcons.receipt,
              title: 'Payment Requests',
              subtitle: 'Request money with receipts or pay inbound requests',
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Request money',
              icon: AppIcons.plus,
              onPressed: _requestMoney,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _tab == 0 ? AppColors.surface3 : AppColors.surface2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text('Incoming', style: TextStyle(fontWeight: FontWeight.w700, color: _tab == 0 ? AppColors.textPrimary : AppColors.muted)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _tab == 1 ? AppColors.surface3 : AppColors.surface2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text('Sent by You', style: TextStyle(fontWeight: FontWeight.w700, color: _tab == 1 ? AppColors.textPrimary : AppColors.muted)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (filtered.isEmpty)
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  children: [
                    Icon(AppIcons.receipt, size: 32, color: AppColors.muted),
                    const SizedBox(height: 10),
                    Text(_tab == 0 ? 'No incoming requests' : 'No outgoing requests', style: AppText.cardTitle),
                  ],
                ),
              )
            else
              for (final req in filtered)
                AppCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(req.counterparty, style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                          Text('₦${req.amount.toStringAsFixed(2)}', style: AppText.tabular.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(req.note, style: AppText.caption),
                      if (req.photoAttachment != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(req.photoAttachment!, height: 90, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusBadge(
                            label: req.status,
                            tone: req.status == 'Paid' ? BadgeTone.good : BadgeTone.warn,
                          ),
                          if (req.isIncoming && req.status == 'Pending')
                            SecondaryButton(
                              label: 'Pay Now',
                              icon: AppIcons.check,
                              onPressed: () => _payRequest(req),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _NewRequestFlow extends StatefulWidget {
  const _NewRequestFlow({required this.onCreated});

  final ValueChanged<PaymentRequestItem> onCreated;

  @override
  State<_NewRequestFlow> createState() => _NewRequestFlowState();
}

class _NewRequestFlowState extends State<_NewRequestFlow> {
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  File? _receiptPhoto;

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _recipientController.text.trim().isNotEmpty &&
      (double.tryParse(_amountController.text.trim()) ?? 0) > 0;

  void _submit() {
    final item = PaymentRequestItem(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      counterparty: _recipientController.text.trim(),
      amount: double.tryParse(_amountController.text.trim()) ?? 0,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : 'Payment request',
      isIncoming: false,
      date: DateTime.now(),
      photoAttachment: _receiptPhoto,
    );
    widget.onCreated(item);
    Navigator.of(context).pop();
    showAppModal(
      context,
      icon: AppIcons.check,
      iconColor: AppColors.gain,
      title: 'Request Sent',
      message: 'Payment request for ₦${item.amount.toStringAsFixed(2)} has been sent to ${item.counterparty}.',
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
              icon: AppIcons.receipt,
              title: 'Request Money',
              subtitle: 'Send a request with an optional bill photo from your device',
            ),
            const SizedBox(height: 22),
            Text('Who are you requesting from?', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            TextField(
              controller: _recipientController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: '@username or phone number'),
            ),
            const SizedBox(height: 22),
            Text('Amount', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '0.00', prefixText: '₦ '),
            ),
            const SizedBox(height: 22),
            Text('What is it for?', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(hintText: 'e.g. Dinner bill or shared groceries'),
            ),
            const SizedBox(height: 22),
            DevicePhotoCard(
              label: 'Attach Bill / Receipt Photo (Camera / Gallery)',
              photo: _receiptPhoto,
              onChanged: (f) => setState(() => _receiptPhoto = f),
              title: 'Snap Bill Receipt',
              hint: 'Take a photo of physical bill or pick screenshot',
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: 'Send Request', onPressed: _canSubmit ? _submit : null),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. PAY LINKS SCREEN
// ==========================================

class PayLinkItem {
  PayLinkItem({
    required this.slug,
    required this.title,
    required this.amount,
    required this.collected,
    required this.isFixedAmount,
  });

  final String slug;
  final String title;
  final double amount;
  double collected;
  final bool isFixedAmount;
}

class PayLinksScreen extends StatefulWidget {
  const PayLinksScreen({super.key});

  @override
  State<PayLinksScreen> createState() => _PayLinksScreenState();
}

class _PayLinksScreenState extends State<PayLinksScreen> {
  final List<PayLinkItem> _links = [
    PayLinkItem(slug: 'pay.scorche.app/design-consult', title: 'UX Design Consultation', amount: 35000, collected: 105000, isFixedAmount: true),
    PayLinkItem(slug: 'pay.scorche.app/scorche-tip', title: 'Support & Tips', amount: 0, collected: 42000, isFixedAmount: false),
  ];

  void _createLink() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NewPayLinkFlow(
          onCreated: (link) => setState(() => _links.insert(0, link)),
        ),
      ),
    );
  }

  void _showLinkDetails(PayLinkItem link) {
    showAppSheet(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(link.title, style: AppText.detailTitle),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Icon(AppIcons.qr, size: 120, color: Colors.black87),
          ),
          const SizedBox(height: 14),
          Text(link.slug, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Copy Link',
                  icon: AppIcons.copy,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    showAppModal(context, icon: AppIcons.copy, title: 'Copied', message: 'Pay link copied to clipboard.');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  label: 'Share',
                  icon: AppIcons.share,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    showAppModal(context, icon: AppIcons.share, title: 'Share Link', message: 'Share link via WhatsApp, Telegram, or SMS.');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
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
              icon: AppIcons.link,
              title: 'Payment Links',
              subtitle: 'Shareable links anyone can use to pay you instantly',
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Create new pay link', icon: AppIcons.plus, onPressed: _createLink),
            const SizedBox(height: 22),
            Text('Your Active Links', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            for (final link in _links)
              GestureDetector(
                onTap: () => _showLinkDetails(link),
                behavior: HitTestBehavior.opaque,
                child: AppCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(link.title, style: AppText.body.copyWith(fontWeight: FontWeight.w700))),
                          Text(link.isFixedAmount ? '₦${link.amount.toStringAsFixed(2)}' : 'Open Amount', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(link.slug, style: AppText.caption.copyWith(color: AppColors.accent)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total collected: ₦${link.collected.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11.5, color: AppColors.gain, fontWeight: FontWeight.w600)),
                          Icon(AppIcons.chevronRight, size: 16, color: AppColors.muted),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NewPayLinkFlow extends StatefulWidget {
  const _NewPayLinkFlow({required this.onCreated});

  final ValueChanged<PayLinkItem> onCreated;

  @override
  State<_NewPayLinkFlow> createState() => _NewPayLinkFlowState();
}

class _NewPayLinkFlowState extends State<_NewPayLinkFlow> {
  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  final _amountController = TextEditingController();
  bool _fixedAmount = true;

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _titleController.text.trim().isNotEmpty;

  void _submit() {
    final slugName = _slugController.text.trim().isNotEmpty ? _slugController.text.trim() : _titleController.text.trim().toLowerCase().replaceAll(' ', '-');
    final link = PayLinkItem(
      slug: 'pay.scorche.app/$slugName',
      title: _titleController.text.trim(),
      amount: _fixedAmount ? (double.tryParse(_amountController.text.trim()) ?? 0) : 0,
      collected: 0,
      isFixedAmount: _fixedAmount,
    );
    widget.onCreated(link);
    Navigator.of(context).pop();
    showAppModal(
      context,
      icon: AppIcons.check,
      iconColor: AppColors.gain,
      title: 'Pay Link Created',
      message: '${link.slug} is now live and ready to receive payments.',
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
            const DetailHeader(icon: AppIcons.link, title: 'Create Pay Link', subtitle: 'Customize title, link name and amount'),
            const SizedBox(height: 22),
            Text('Link Title / Purpose', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'e.g. Photography Session'),
            ),
            const SizedBox(height: 22),
            Text('Custom URL Slug', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            TextField(
              controller: _slugController,
              decoration: const InputDecoration(hintText: 'photo-session', prefixText: 'pay.scorche.app/'),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fixed Amount', style: AppText.sectionTitle),
                Switch(
                  value: _fixedAmount,
                  activeThumbColor: AppColors.accent,
                  onChanged: (v) => setState(() => _fixedAmount = v),
                ),
              ],
            ),
            if (_fixedAmount) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: '0.00', prefixText: '₦ '),
              ),
            ],
            const SizedBox(height: 28),
            PrimaryButton(label: 'Generate Pay Link', onPressed: _canSubmit ? _submit : null),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. BULK TRANSFER SCREEN
// ==========================================

class BulkTransferRecipient {
  BulkTransferRecipient({
    required this.name,
    required this.bank,
    required this.accountNumber,
    required this.amount,
  });

  String name;
  String bank;
  String accountNumber;
  double amount;
}

class BulkTransferScreen extends StatefulWidget {
  const BulkTransferScreen({super.key});

  @override
  State<BulkTransferScreen> createState() => _BulkTransferScreenState();
}

class _BulkTransferScreenState extends State<BulkTransferScreen> {
  final List<BulkTransferRecipient> _recipients = [
    BulkTransferRecipient(name: 'Adaeze Okafor', bank: 'Access Bank', accountNumber: '0123456789', amount: 75000),
    BulkTransferRecipient(name: 'Chidi Eze', bank: 'GTBank', accountNumber: '0234567890', amount: 50000),
    BulkTransferRecipient(name: 'Tobi Adeyemi', bank: 'Zenith Bank', accountNumber: '0345678901', amount: 120000),
  ];

  double get _totalAmount => _recipients.fold(0, (sum, r) => sum + r.amount);

  void _addRecipient() {
    final nameCtrl = TextEditingController();
    final acctCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String bank = 'Access Bank';

    showAppSheet(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Recipient', style: AppText.detailTitle),
            const SizedBox(height: 14),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Beneficiary Name', hintText: 'e.g. John Doe')),
            const SizedBox(height: 10),
            TextField(controller: acctCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Account Number', hintText: '10 digits')),
            const SizedBox(height: 10),
            TextField(controller: amtCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount', prefixText: '₦ ')),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Add to Batch',
              onPressed: () {
                final amt = double.tryParse(amtCtrl.text.trim()) ?? 0;
                if (nameCtrl.text.trim().isNotEmpty && amt > 0) {
                  setState(() {
                    _recipients.add(BulkTransferRecipient(
                      name: nameCtrl.text.trim(),
                      bank: bank,
                      accountNumber: acctCtrl.text.trim(),
                      amount: amt,
                    ));
                  });
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _executeBatch() {
    showAppModal(
      context,
      icon: AppIcons.check,
      iconColor: AppColors.gain,
      title: 'Batch Transfer Successful',
      message: 'Disbursed ₦${_totalAmount.toStringAsFixed(2)} across ${_recipients.length} recipients. Receipt generated.',
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
              title: 'Bulk Transfer',
              subtitle: 'Send money to multiple people in a single transaction',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: PrimaryButton(label: 'Add Recipient', icon: AppIcons.plus, onPressed: _addRecipient)),
                const SizedBox(width: 8),
                Expanded(
                  child: SecondaryButton(
                    label: 'Import CSV',
                    icon: AppIcons.download,
                    onPressed: () {
                      showAppModal(context, icon: AppIcons.check, title: 'CSV Imported', message: 'Loaded 3 payroll recipients from CSV template.');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            AppCard(
              color: AppColors.accentSoft,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Batch Payout', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text('₦${_totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    ],
                  ),
                  Text('${_recipients.length} recipients', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.accent)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Recipients Queue', style: AppText.sectionTitle),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
              child: Column(
                children: [
                  for (int i = 0; i < _recipients.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
                            child: Icon(AppIcons.building, size: 16, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_recipients[i].name, style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                                Text('${_recipients[i].bank} · ${_recipients[i].accountNumber}', style: AppText.caption),
                              ],
                            ),
                          ),
                          Text('₦${_recipients[i].amount.toStringAsFixed(2)}', style: AppText.tabular.copyWith(fontWeight: FontWeight.w800, fontSize: 13)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _recipients.removeAt(i)),
                            child: const Icon(AppIcons.trash, size: 16, color: AppColors.loss),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Execute Bulk Transfer (₦${_totalAmount.toStringAsFixed(2)})',
              onPressed: _recipients.isNotEmpty ? _executeBatch : null,
            ),
          ],
        ),
      ),
    );
  }
}

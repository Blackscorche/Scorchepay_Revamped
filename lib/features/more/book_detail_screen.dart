import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_toggle.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/charts/simple_bar_chart.dart';
import '../../core/widgets/detail_header.dart';
import '../../core/widgets/device_photo_card.dart';
import '../../core/widgets/flag_chip.dart';
import '../../core/widgets/icon_action_button.dart';
import '../../core/widgets/list_row.dart';
import '../../core/widgets/photo_picker_sheet.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../state/models/demo_account.dart';
import '../../state/models/savings.dart';
import '../../state/providers/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../auth/kyc_screen.dart';
import '../bills/airtime_screen.dart';
import '../bills/bill_payment_screen.dart';
import '../bills/data_screen.dart';
import '../bills/gift_card_screen.dart';
import '../flows/escrow/create_escrow_screen.dart';
import 'escrow_detail_screen.dart';
import '../flows/savings/goal_setup_screen.dart';
import '../flows/savings/group_savings_detail_screen.dart';
import '../flows/savings/savings_goal_detail_screen.dart';
import '../send/scan_qr_screen.dart';
import '../send/send_extras_screens.dart';
import '../send/split_bill_screen.dart';
import '../wallet/currency_deposit_screen.dart';
import 'create_flow_screen.dart';
import 'group_goal_detail_screen.dart';
import 'savings_goal_detail_screen.dart' as more_savings;

/// Generic "book" detail screen — full standard implementation of all roadmap features.
class BookDetailScreen extends ConsumerStatefulWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  int _sendTab = 0;
  int _receiveTab = 0;
  int _transactionsTab = 0;
  int _analyticsPeriod = 1; // 0: 7D, 1: 30D, 2: 90D, 3: 1Y
  bool _bankAccountVerified = false;
  final _bankAccountController = TextEditingController();
  final _aiChatController = TextEditingController();
  final _chatScrollController = ScrollController();
  File? _attachedAiPhoto;

  final List<(String, bool, File?)> _aiMessages = [
    ("Hi Scorche! I'm your AI financial coach. How can I help you grow, automate and optimize your money today?", false, null),
    ("You're on track to hit your 'New Car' goal 3 weeks early if you keep this pace!", false, null),
  ];

  final Map<String, bool> _autoDebitToggles = {
    'Emergency Fund': true,
    'New Car 2027': true,
    'Family House Fund (Group)': true,
    'Crypto DCA Vault': false,
  };

  final Map<String, bool> _automationToggles = {
    'Round-up savings on every card swipe': true,
    'Auto-pay Ikeja Electric bill when due': true,
    'Weekly auto-save ₦10,000 to Emergency Fund': true,
    'Auto-convert USDT → NGN on receipt': false,
    'Sweep excess balance above ₦500,000 to 14% yield': true,
  };

  final Map<String, bool> _securityToggles = {
    'PIN confirmation on transfers': true,
    'Biometrics (Face / Touch ID)': true,
    '2FA Authentication': true,
    'Trusted device verification': true,
    'Instant login push alerts': true,
    'International roaming fraud lock': false,
  };

  @override
  void dispose() {
    _bankAccountController.dispose();
    _aiChatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _openBook(String id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: id)),
    );
  }

  void _info(IconData icon, String title, String message) {
    showAppModal(context, icon: icon, title: title, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final book = MockData.bookById(widget.bookId);
    if (book == null) {
      return Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                IconCircleButton(
                    icon: AppIcons.chevronLeft,
                    onTap: () => Navigator.of(context).pop()),
                const SizedBox(height: 40),
                const Text('Feature not found', style: AppText.cardTitle),
              ],
            ),
          ),
        ),
      );
    }

    // AI Assistant has its own full-screen chat scaffold with fixed bottom bar
    if (book.type == BookType.ai) {
      return Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: _Header(book: book),
              ),
              const Divider(color: AppColors.hairline, height: 1),
              Expanded(child: _buildAiChat()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            _Header(book: book),
            const SizedBox(height: 16),
            _buildBody(book),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BookItem book) {
    switch (book.type) {
      case BookType.simpleList:
        return _simpleList(book);
      case BookType.send:
        return _send();
      case BookType.receive:
        return _receive();
      case BookType.bills:
        return _bills();
      case BookType.escrow:
        return _escrow();
      case BookType.merchant:
        return _merchant();
      case BookType.crossBorder:
        return _crossBorder();
      case BookType.automation:
        return _automation();
      case BookType.multiCurrency:
        return _multiCurrency();
      case BookType.savings:
        return _savings();
      case BookType.group:
        return _group();
      case BookType.transactions:
        return _transactions();
      case BookType.insights:
        return _insights();
      case BookType.analytics:
        return _analytics();
      case BookType.ai:
        return _buildAiChat();
      case BookType.rewards:
        return _rewards();
      case BookType.profile:
        return _profile();
      case BookType.security:
        return _security();
      case BookType.notifications:
        return _notifications();
      case BookType.business:
        return _business();
      case BookType.developer:
        return _developer();
    }
  }

  Widget _simpleList(BookItem book) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
      child: Column(
        children: [
          for (int i = 0; i < book.features.length; i++)
            AppListRow(
              icon: AppIcons.check,
              title: book.features[i],
              showDivider: i != book.features.length - 1,
            ),
        ],
      ),
    );
  }

  // =======================================================
  // MULTI-CURRENCY VAULT & GLOBAL ACCOUNTS
  // =======================================================

  Widget _multiCurrency() {
    final currencyDetails = [
      (
        'NGN',
        'Nigerian Naira',
        '₦6,264,000.00',
        CountryFlag.ng,
        'Providus Bank · 8104562311',
        'Local NGN Virtual Account'
      ),
      (
        'USD',
        'United States Dollar',
        '\$2,450.00',
        CountryFlag.us,
        'Community Federal Savings · Routing: 026073150 · Acc: 98234109',
        'US Wire & ACH Account'
      ),
      (
        'GBP',
        'British Pound Sterling',
        '£820.50',
        CountryFlag.gb,
        'ClearBank Ltd · Sort: 04-00-75 · Acc: 18293012',
        'UK Faster Payments Account'
      ),
      (
        'EUR',
        'Euro',
        '€1,100.00',
        CountryFlag.eu,
        'Banking Circle · IBAN: DE89 3704 0044 0532 0130 00',
        'SEPA Eurozone Account'
      ),
      (
        'GHS',
        'Ghanaian Cedi',
        'GH₵3,400.00',
        CountryFlag.gh,
        'MTN MoMo · 0244192039',
        'Ghana Mobile Money Wallet'
      ),
      (
        'KES',
        'Kenyan Shilling',
        'KSh 42,000.00',
        CountryFlag.ke,
        'M-Pesa Paybill · 522522 · Acc: 89012',
        'Kenya M-Pesa Account'
      ),
      (
        'USDT',
        'Tether USD (Stablecoin)',
        '\$1,500.00',
        CountryFlag.us,
        'TRON (TRC-20) / Polygon (ERC-20)',
        'Multi-chain Crypto Vault'
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Portfolio Net Worth Card
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Expanded(
                    child: Text('Total Multi-Currency Net Worth',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(width: 8),
                  StatusBadge(label: '7 Currencies Active', tone: BadgeTone.good),
                ],
              ),
              const SizedBox(height: 6),
              const Text('₦16,240,850.00',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5)),
              const SizedBox(height: 2),
              const Text('≈ \$10,508.00 USD · €9,710.00 EUR · £8,320.00 GBP',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 18),
              // Prominent Action Bar
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Add Money',
                      icon: AppIcons.plus,
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const CurrencyDepositScreen(
                              code: 'NGN',
                              flag: CountryFlag.ng,
                              amount: '₦6,264,000.00'))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Transfer',
                      icon: AppIcons.arrowUpRight,
                      onPressed: () => _openBook('crossborder'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Exchange / Convert',
                      icon: AppIcons.repeat,
                      onPressed: _openConvertCurrencies,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Withdraw',
                      icon: AppIcons.download,
                      onPressed: _openWithdrawModal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SectionTitle('Your Global Accounts'),
        for (final c in currencyDetails)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FlagChip(flag: c.$4),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.$2,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.textPrimary)),
                            Text(c.$6,
                                style: const TextStyle(
                                    fontSize: 11.5, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      Text(c.$3,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                  const Divider(color: AppColors.hairline, height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            c.$5,
                            style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _info(AppIcons.copy, 'Account Details Copied',
                              '${c.$1} account details copied to clipboard.'),
                          child: const Text('Copy',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => CurrencyDepositScreen(
                                  code: c.$1, flag: c.$4, amount: c.$3))),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface3,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: const Text('Deposit',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openConvertCurrenciesWithFrom(c.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface3,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: const Text('Convert',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openWithdrawCurrency(c.$1, c.$3),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: const Text('Withdraw',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _openConvertCurrencies() {
    _openConvertCurrenciesWithFrom('USD');
  }

  void _openConvertCurrenciesWithFrom(String from) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreateFlowScreen(
        icon: AppIcons.repeat,
        title: 'Instant Currency Exchange',
        subtitle: 'Convert balances at zero markup and live interbank rate',
        fields: [
          CreateField.chips(label: 'From Balance', chips: const ['USD', 'NGN', 'GBP', 'EUR', 'GHS', 'USDT']),
          CreateField.chips(label: 'To Balance', chips: const ['NGN', 'USD', 'GBP', 'EUR', 'GHS', 'USDT']),
          const CreateField.text(label: 'Exchange Amount', hint: '0.00'),
        ],
        submitLabel: 'Execute Instant Conversion',
        successTitle: 'Exchange Complete',
        successMessage: (v) => 'Exchanged ${v[2]} ${v[0]} into ${v[1]} at the live guaranteed rate.',
      ),
    ));
  }

  void _openWithdrawModal() {
    _openWithdrawCurrency('USD', '\$2,450.00');
  }

  void _openWithdrawCurrency(String code, String balance) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreateFlowScreen(
        icon: AppIcons.download,
        title: 'Withdraw $code Funds',
        subtitle: 'Available balance: $balance',
        fields: [
          CreateField.chips(label: 'Withdrawal Destination', chips: const [
            'Local Bank Account (Instant)',
            'Wire Transfer (ACH / SEPA / SWIFT)',
            'Crypto Wallet (USDT TRC20/ERC20)',
            'Mobile Money (MoMo / M-Pesa)'
          ]),
          const CreateField.text(label: 'Amount to Withdraw', hint: '0.00'),
          const CreateField.text(label: 'Destination Account / Address', hint: 'Account No, IBAN or 0x Wallet Address'),
          const CreateField.text(label: 'Account Holder Name', hint: 'Full legal name'),
        ],
        submitLabel: 'Confirm & Withdraw Funds',
        successTitle: 'Withdrawal Initiated',
        successMessage: (v) => 'Withdrawal of ${v[1]} $code to ${v[3]} (${v[0]}) is processing. Estimated arrival: <15 mins.',
      ),
    ));
  }

  // =======================================================
  // SAVINGS & AUTO-DEBIT HUB
  // =======================================================

  Widget _savings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Auto-Debit Banner Card
        AppCard(
          color: AppColors.accentSoft,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(AppIcons.repeat, size: 18, color: AppColors.accent),
                  SizedBox(width: 8),
                  Text('Smart Auto-Debit Engine', style: AppText.cardTitle),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Auto-debit automatically funds your savings goals from your linked card or wallet every payday or chosen schedule.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Expanded(
                    child: Text('Linked Card: •••• 4891 (Access)',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(width: 8),
                  StatusBadge(label: 'Auto-Debit Active', tone: BadgeTone.good),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final g in MockData.savingsGoals)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                  color: AppColors.surface2,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(g.icon, size: 16, color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(g.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                                      overflow: TextOverflow.ellipsis),
                                  Text('14.5% APY · Auto-saves ₦10k weekly',
                                      style: AppText.caption,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(label: g.tag, tone: _goalTone(g.tagColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppProgressBar(value: g.progress),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${g.saved} saved', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text('${(g.progress * 100).round()}% of ${g.target}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const Divider(color: AppColors.hairline, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: const [
                            Icon(AppIcons.repeat, size: 14, color: AppColors.muted),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text('Auto-Debit on Payday',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppToggle(
                        value: _autoDebitToggles[g.name] ?? true,
                        onChanged: (v) => setState(() => _autoDebitToggles[g.name] = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Top Up',
                          icon: AppIcons.plus,
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => more_savings.SavingsGoalDetailScreen(goal: g),
                          )),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SecondaryButton(
                          label: 'Withdraw',
                          icon: AppIcons.minus,
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => more_savings.SavingsGoalDetailScreen(goal: g),
                          )),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        PrimaryButton(
          label: 'Create New Savings Goal',
          icon: AppIcons.plus,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => GoalSetupScreen(type: SavingsType.goal),
          )),
        ),
      ],
    );
  }

  BadgeTone _goalTone(Color? c) {
    if (c == AppColors.gain) return BadgeTone.good;
    if (c == AppColors.info) return BadgeTone.info;
    return BadgeTone.neutral;
  }

  Widget _group() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          color: AppColors.accentSoft,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(AppIcons.users, size: 18, color: AppColors.accent),
                  SizedBox(width: 8),
                  Text('Rotating Group Pools (Ajo / Esusu)', style: AppText.cardTitle),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Members auto-contribute each cycle. Payouts rotate automatically to the next assigned member with fraud-proof escrow protection.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const GroupGoalDetailScreen(
              name: 'Family House Fund',
              memberLabels: ['A', 'B', 'C', '+4'],
              savedLabel: '₦2.16M of ₦4M · 7 members',
              progress: 0.54,
              progressColor: AppColors.info,
            ),
          )),
          behavior: HitTestBehavior.opaque,
          child: AppCard(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(
                      child: Text('Family House Fund',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(width: 8),
                    _StackAvatars(labels: ['A', 'B', 'C', '+4']),
                  ],
                ),
                const SizedBox(height: 10),
                const AppProgressBar(value: 0.54, color: AppColors.info),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(
                      child: Text('₦2.16M of ₦4M · Cycle 3/7',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(width: 8),
                    Text('Next Payout: You', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gain)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const GroupGoalDetailScreen(
              name: 'Squad Trip 2027',
              memberLabels: ['K', 'N', 'T'],
              savedLabel: '\$440 of \$2,000 · 3 members',
              progress: 0.22,
              progressColor: AppColors.gain,
            ),
          )),
          behavior: HitTestBehavior.opaque,
          child: AppCard(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(
                      child: Text('Squad Trip 2027',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(width: 8),
                    _StackAvatars(labels: ['K', 'N', 'T']),
                  ],
                ),
                const SizedBox(height: 10),
                const AppProgressBar(value: 0.22, color: AppColors.gain),
                const SizedBox(height: 10),
                const Text('\$440 of \$2,000 · 3 members', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Start a Group Savings Pool (Esusu)',
          icon: AppIcons.plus,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => GoalSetupScreen(type: SavingsType.group),
          )),
        ),
      ],
    );
  }

  // =======================================================
  // INSIGHTS & FINANCIAL INTELLIGENCE
  // =======================================================

  Widget _insights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Health Score
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Expanded(
                    child: Text('Financial Health Score',
                        style: AppText.cardTitle,
                        overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(width: 8),
                  StatusBadge(label: '88 / 100 · Excellent', tone: BadgeTone.good),
                ],
              ),
              const SizedBox(height: 10),
              const AppProgressBar(value: 0.88),
              const SizedBox(height: 10),
              const Text('Top 5% saver this month. Savings velocity is +28% higher than last quarter.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
            ],
          ),
        ),
        const SectionTitle('Market Trends & Economic News'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: const [
              AppListRow(
                icon: AppIcons.chartLine,
                title: 'Naira FX Liquidity Update',
                subtitle: 'CBN interbank rate holds steady at ₦1,542.40 / \$1',
                trailing: StatusBadge(label: 'Market', tone: BadgeTone.info),
              ),
              AppListRow(
                icon: AppIcons.coins,
                title: 'Crypto Market Sentiment',
                subtitle: 'Fear & Greed Index at 74 (Bullish) · BTC \$96.4k',
                trailing: StatusBadge(label: '+4.2%', tone: BadgeTone.good),
              ),
              AppListRow(
                icon: AppIcons.bolt,
                title: 'Smart Spending Advice',
                subtitle: 'You spent 24% less on dining this week. Est. savings: +₦45k',
                showDivider: false,
                trailing: StatusBadge(label: 'Saved', tone: BadgeTone.good),
              ),
            ],
          ),
        ),
        const SectionTitle('Monthly Category Budgets'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: const [
              AppListRow(icon: AppIcons.phone, title: 'Bills & Utilities', subtitle: '₦42,000 spent of ₦60,000 cap', trailing: StatusBadge(label: '70%', tone: BadgeTone.good)),
              AppListRow(icon: AppIcons.package, title: 'Shopping & Groceries', subtitle: '₦88,000 spent of ₦100,000 cap', trailing: StatusBadge(label: '88%', tone: BadgeTone.warn)),
              AppListRow(icon: AppIcons.coins, title: 'Crypto Investments', subtitle: '₦120,000 invested of ₦150,000 target', showDivider: false, trailing: StatusBadge(label: '80%', tone: BadgeTone.info)),
            ],
          ),
        ),
      ],
    );
  }

  // =======================================================
  // ANALYTICS DASHBOARD (DISTINCT FROM INSIGHTS)
  // =======================================================

  Widget _analytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TabBar(
          tabs: const ['7 Days', '30 Days', '90 Days', '1 Year'],
          selected: _analyticsPeriod,
          onChanged: (i) => setState(() => _analyticsPeriod = i),
        ),
        Row(
          children: const [
            Expanded(child: _StatMini(label: 'Total Inflow', value: '₦1,850,000', up: true)),
            SizedBox(width: 8),
            Expanded(child: _StatMini(label: 'Total Outflow', value: '₦432,100')),
            SizedBox(width: 8),
            Expanded(child: _StatMini(label: 'Net Savings', value: '₦1.41M', up: true)),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Outflow by Category', style: AppText.cardTitle),
                  Text('Breakdown', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 12),
              const SimpleBarChart(data: [
                BarDatum('Bills', 62, AppColors.catBlue),
                BarDatum('Data', 88, AppColors.catOrange),
                BarDatum('Food', 45, AppColors.catAqua),
                BarDatum('Crypto', 30, AppColors.catYellow),
                BarDatum('Transfers', 75, AppColors.catMagenta),
                BarDatum('Other', 20, AppColors.catGreen),
              ]),
            ],
          ),
        ),
        const SectionTitle('Top Beneficiaries & Merchants'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: const [
              AppListRow(icon: AppIcons.user, title: '@ada_b (Ada Balogun)', subtitle: '12 transactions · ₦380,000 total', showChevron: false),
              AppListRow(icon: AppIcons.bolt, title: 'Ikeja Electric DisCo', subtitle: '4 payments · ₦48,000 total', showChevron: false),
              AppListRow(icon: AppIcons.building, title: 'Access Bank Transfer', subtitle: '8 payouts · ₦510,000 total', showChevron: false, showDivider: false),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: 'Export Certified Audit Statement (PDF / CSV)',
          icon: AppIcons.download,
          onPressed: () => _info(AppIcons.check, 'Statement Exported',
              'Your financial analytics report has been downloaded to device storage.'),
        ),
      ],
    );
  }

  // =======================================================
  // AI ASSISTANT & CHAT
  // =======================================================

  Widget _buildAiChat() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            itemCount: _aiMessages.length,
            itemBuilder: (context, i) {
              final m = _aiMessages[i];
              return Align(
                alignment: m.$2 ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: m.$2 ? AppColors.accent : AppColors.surface2,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (m.$3 != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(m.$3!, height: 140, width: double.infinity, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        m.$1,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: m.$2 ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Quick suggestions
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Row(
            children: [
              _aiChip('How much did I spend this week?'),
              const SizedBox(width: 8),
              _aiChip('Analyze my savings goal pace'),
              const SizedBox(width: 8),
              _aiChip('Best FX rate to convert USD?'),
            ],
          ),
        ),
        // Bottom sticky input bar
        Container(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          decoration: const BoxDecoration(
            color: AppColors.page,
            border: Border(top: BorderSide(color: AppColors.hairline)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_attachedAiPhoto != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_attachedAiPhoto!, width: 40, height: 40, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Receipt / Screenshot attached for AI', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _attachedAiPhoto = null),
                        child: const Icon(AppIcons.trash, size: 16, color: AppColors.loss),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final res = await showPhotoPickerSheet(context, title: 'Attach Screenshot / Receipt for AI');
                      if (res != null && res.file != null) {
                        setState(() => _attachedAiPhoto = res.file);
                      }
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(AppIcons.camera, size: 20, color: AppColors.accent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _aiChatController,
                      decoration: const InputDecoration(
                        hintText: 'Ask financial coach or attach receipt...',
                      ),
                      onSubmitted: (_) => _sendAiMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendAiMessage,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(AppIcons.send, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aiChip(String label) {
    return GestureDetector(
      onTap: () {
        _aiChatController.text = label;
        _sendAiMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _sendAiMessage() {
    final txt = _aiChatController.text.trim();
    if (txt.isEmpty && _attachedAiPhoto == null) return;
    setState(() {
      _aiMessages.add((txt.isNotEmpty ? txt : 'Analyzed attached image', true, _attachedAiPhoto));
      _aiChatController.clear();
      _attachedAiPhoto = null;
      _aiMessages.add((
        "I've analyzed your financial data! Based on your cashflow and savings velocity, allocating ₦20,000 weekly into 14.5% APY yield will help you hit your targets 1 month ahead of schedule.",
        false,
        null
      ));
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // =======================================================
  // REWARDS & VIP LOYALTY CLUB
  // =======================================================

  Widget _rewards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // VIP Card
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Expanded(
                    child: Text('VIP LOYALTY CLUB',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accent, letterSpacing: 0.8),
                        overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(width: 8),
                  StatusBadge(label: 'Silver Tier', tone: BadgeTone.good),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Silver Tier Member',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('Perks: 0.5% Cashback on transfers · 2 free wire payouts monthly · Priority 24/7 VIP Concierge.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
              const SizedBox(height: 14),
              const AppProgressBar(value: 0.64),
              const SizedBox(height: 8),
              const Text('640 / 1,000 Tier Points (360 pts to Gold Tier)', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
            ],
          ),
        ),
        const SectionTitle('Daily Streak & Bonuses'),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Expanded(
                    child: Text('5-Day Check-in Streak 🔥',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(width: 8),
                  Text('+₦2,500 bonus at Day 7', style: TextStyle(fontSize: 11.5, color: AppColors.gain, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (int d = 1; d <= 7; d++) ...[
                    if (d > 1) const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: d <= 5 ? AppColors.accentSoft : AppColors.surface2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: d <= 5 ? AppColors.accent : AppColors.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('D$d', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: d <= 5 ? AppColors.accent : AppColors.muted)),
                            const SizedBox(height: 2),
                            Icon(d <= 5 ? AppIcons.check : AppIcons.giftCard, size: 14, color: d <= 5 ? AppColors.accent : AppColors.muted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: "Claim Today's ₦500 Streak Reward",
                icon: AppIcons.check,
                onPressed: () => _info(AppIcons.check, 'Reward Claimed', '₦500 daily streak bonus added to your spendable wallet.'),
              ),
            ],
          ),
        ),
        const SectionTitle('Cashback & Referrals'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Available Cashback', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        SizedBox(height: 2),
                        Text('₦4,120.00', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.gain)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SecondaryButton(
                    label: 'Claim to Wallet',
                    icon: AppIcons.download,
                    onPressed: () => _info(AppIcons.check, 'Cashback Claimed', '₦4,120 credited to your main NGN wallet.'),
                  ),
                ],
              ),
              const Divider(color: AppColors.hairline, height: 24),
              const Text('Your Referral Code', style: AppText.cardTitle),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('SCORCHE-3F9K',
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.accent,
                              letterSpacing: 1),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _info(AppIcons.copy, 'Code Copied',
                          'Referral code copied to clipboard.'),
                      child: const Text('Copy Link',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text('Earn ₦5,000 instant cashback for every friend who joins with your link.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  // =======================================================
  // PROFILE & SETTINGS
  // =======================================================

  Widget _profile() {
    final profile = ref.watch(userProfileProvider);
    final photo = profile.photoFile;
    final initials = profile.displayName.isNotEmpty
        ? (profile.displayName.length >= 2
            ? profile.displayName.substring(0, 2).toUpperCase()
            : profile.displayName.toUpperCase())
        : 'SC';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  final result = await showPhotoPickerSheet(
                    context,
                    title: 'Update Profile Photo',
                    hasPhoto: photo != null,
                  );
                  if (result != null) {
                    await ref
                        .read(userProfileProvider.notifier)
                        .setPhoto(result.removed ? null : result.file?.path);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: photo != null ? null : AppColors.surface2,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderStrong, width: 2),
                        image: photo != null
                            ? DecorationImage(
                                image: FileImage(photo), fit: BoxFit.cover)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: photo == null
                          ? Text(
                              initials,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 26,
                                  color: AppColors.textSecondary),
                            )
                          : null,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 2),
                        ),
                        child: const Icon(AppIcons.camera,
                            size: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(profile.displayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 3),
              Text('@${profile.username} · ${profile.email}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 12),
              StatusBadge(
                  label: '${profile.tier} ${profile.kycStatus}',
                  tone: BadgeTone.good),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Edit Profile Information',
          icon: AppIcons.user,
          onPressed: _openEditProfileModal,
        ),
        const SizedBox(height: 20),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              AppListRow(
                icon: AppIcons.idCard,
                title: 'Verification & KYC (ID + Selfie)',
                trailing: StatusBadge(label: profile.tier, tone: BadgeTone.good),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const KycScreen())),
              ),
              AppListRow(
                icon: AppIcons.globe,
                title: 'Preferred Currency',
                subtitle: 'NGN (Nigerian Naira)',
                onTap: () => _openBook('multicurrency'),
              ),
              AppListRow(
                icon: AppIcons.lock,
                title: 'Security & Biometrics',
                subtitle: 'PIN, Face ID, 2FA',
                onTap: () => _openBook('security'),
              ),
              AppListRow(
                icon: AppIcons.bell,
                title: 'Notification Preferences',
                subtitle: 'Push, SMS & Email alerts',
                onTap: () => _openBook('notifications'),
              ),
              AppListRow(
                icon: AppIcons.trophy,
                title: 'Referral Rewards',
                subtitle: 'Earn ₦5,000 per invite',
                showDivider: false,
                onTap: () => _openBook('rewards'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openEditProfileModal() {
    final profile = ref.read(userProfileProvider);
    final nameCtrl = TextEditingController(text: profile.displayName);
    final unameCtrl = TextEditingController(text: profile.username);
    final emailCtrl = TextEditingController(text: profile.email);
    final phoneCtrl = TextEditingController(text: profile.phone);
    final bioCtrl = TextEditingController(text: profile.bio);

    showAppSheet(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Profile', style: AppText.detailTitle),
          const SizedBox(height: 16),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Display Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: unameCtrl,
            decoration: const InputDecoration(labelText: 'Username', prefixText: '@'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: emailCtrl,
            decoration: const InputDecoration(labelText: 'Email Address'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: phoneCtrl,
            decoration: const InputDecoration(labelText: 'Phone Number'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: bioCtrl,
            decoration: const InputDecoration(labelText: 'Bio / Tagline'),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Save Changes',
            onPressed: () async {
              await ref.read(userProfileProvider.notifier).updateProfile(
                    displayName: nameCtrl.text.trim(),
                    username: unameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    bio: bioCtrl.text.trim(),
                  );
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) {
                showAppModal(
                  context,
                  icon: AppIcons.check,
                  iconColor: AppColors.gain,
                  title: 'Profile Updated',
                  message: 'Your personal information has been saved.',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // =======================================================
  // PAY & TRANSFERS
  // =======================================================

  static const _sendTabs = ['Username', 'QR', 'Bank', 'Address', 'Saved'];
  static const _receiveTabs = ['Username', 'Bank', 'Crypto', 'Link'];

  Widget _send() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TabBar(
            tabs: _sendTabs,
            selected: _sendTab,
            onChanged: (i) => setState(() => _sendTab = i)),
        switch (_sendTab) {
          1 => _sendQr(),
          2 => _sendBank(),
          3 => _sendAddress(),
          4 => _sendSaved(),
          _ => _sendUsername(),
        },
      ],
    );
  }

  Widget _sendUsername() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _searchField(icon: AppIcons.user, hint: '@username or search contacts'),
        const SizedBox(height: 6),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              for (final a in DemoAccounts.all)
                AppListRow(
                  icon: AppIcons.user,
                  title: a.username,
                  subtitle: '${a.displayName} · Verified contact',
                  showChevron: false,
                  showDivider: a != DemoAccounts.all.last,
                  onTap: () => _info(AppIcons.send, 'Send to ${a.displayName}', 'Enter an amount to transfer to ${a.username} instantly with zero fees.'),
                ),
            ],
          ),
        ),
        const SectionTitle('More ways to send'),
        _iconGrid([
          _GridEntry(
              AppIcons.calendar,
              'Scheduled',
              null,
              () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ScheduledPaymentsScreen()))),
          _GridEntry(
              AppIcons.repeat,
              'Recurring',
              null,
              () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const RecurringPaymentsScreen()))),
          _GridEntry(
              AppIcons.receipt,
              'Requests',
              null,
              () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RequestsScreen()))),
          _GridEntry(
              AppIcons.link,
              'Pay Links',
              null,
              () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PayLinksScreen()))),
          _GridEntry(
              AppIcons.package,
              'Split Bill',
              null,
              () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SplitBillScreen()))),
          _GridEntry(
              AppIcons.package,
              'Bulk',
              null,
              () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const BulkTransferScreen()))),
        ]),
      ],
    );
  }

  Widget _sendQr() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: const Icon(AppIcons.qr,
                size: 38, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text('Scan a QR code',
              style: AppText.cardTitle, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          const Text(
            'Point your device camera at any ScorchePay, bank or crypto QR code to send instantly.',
            style: TextStyle(
                fontSize: 12, color: AppColors.textSecondary, height: 1.45),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Open camera scanner',
            icon: AppIcons.qr,
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ScanQrScreen())),
          ),
        ],
      ),
    );
  }

  Widget _sendBank() {
    final canVerify = _bankAccountController.text.trim().length >= 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _searchField(
          icon: AppIcons.building,
          hint: 'Enter 10-digit account number',
          controller: _bankAccountController,
          onChanged: (_) => setState(() => _bankAccountVerified = false),
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: const Column(
            children: [
              AppListRow(
                  icon: AppIcons.building,
                  title: 'Access Bank',
                  subtitle: 'Tap to change destination bank',
                  showDivider: false),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_bankAccountVerified) ...[
          AppCard(
            color: AppColors.accentSoft,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: const Row(
              children: [
                Icon(AppIcons.check, size: 16, color: AppColors.accent),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Adaeze N. Okafor · Verified',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Proceed to Amount',
            onPressed: () => _info(AppIcons.check, 'Transfer Initiated',
                'Enter an amount to complete the bank transfer to Adaeze N. Okafor at Access Bank.'),
          ),
        ] else
          PrimaryButton(
            label: 'Verify Bank Account',
            onPressed: canVerify
                ? () => setState(() => _bankAccountVerified = true)
                : null,
          ),
        const SectionTitle('Saved Bank Beneficiaries'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: const Column(
            children: [
              AppListRow(
                  icon: AppIcons.building,
                  title: 'John Adeyemi',
                  subtitle: 'GTBank · 0123456789',
                  showChevron: false),
              AppListRow(
                  icon: AppIcons.building,
                  title: 'Blessing Okoro',
                  subtitle: 'Access Bank · 0098765432',
                  showChevron: false,
                  showDivider: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sendAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _searchField(icon: AppIcons.link, hint: 'Paste wallet address (0x... or bc1...)'),
        const SectionTitle('Network', topPad: 6),
        const _NetworkChips(),
        const SectionTitle('Recent Addresses'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: const Column(
            children: [
              AppListRow(
                  icon: AppIcons.coins,
                  title: '0x8f2a…9c31',
                  subtitle: 'Ethereum (ERC-20) · last used 3d ago',
                  showChevron: false),
              AppListRow(
                  icon: AppIcons.coins,
                  title: 'bc1qxy…09gh',
                  subtitle: 'Bitcoin Native · last used 1w ago',
                  showChevron: false,
                  showDivider: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sendSaved() {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
      child: const Column(
        children: [
          AppListRow(
              icon: AppIcons.user,
              title: '@ada_b',
              subtitle: 'Saved · ScorchePay ID',
              showChevron: false),
          AppListRow(
              icon: AppIcons.building,
              title: 'John Adeyemi',
              subtitle: 'Saved · GTBank',
              showChevron: false),
          AppListRow(
              icon: AppIcons.coins,
              title: 'chidi.eth',
              subtitle: 'Saved · Ethereum wallet',
              showChevron: false),
          AppListRow(
              icon: AppIcons.user,
              title: '@kwame_gh',
              subtitle: 'Saved · Mobile Money',
              showChevron: false,
              showDivider: false),
        ],
      ),
    );
  }

  Widget _receive() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TabBar(
            tabs: _receiveTabs,
            selected: _receiveTab,
            onChanged: (i) => setState(() => _receiveTab = i)),
        switch (_receiveTab) {
          1 => _receiveBank(),
          2 => _receiveCrypto(),
          3 => _receiveLink(),
          _ => _receiveUsername(),
        },
      ],
    );
  }

  Widget _receiveUsername() {
    final profile = ref.watch(userProfileProvider);
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 180,
            height: 180,
            margin: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: const Icon(AppIcons.qr, size: 120, color: Colors.black87),
          ),
          Text('@${profile.username}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 3),
          const Text('Universal QR · Bank, Wallet & Crypto in one',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: SecondaryButton(
                      label: 'Copy ID',
                      icon: AppIcons.copy,
                      onPressed: () => _info(AppIcons.copy, 'Copied',
                          '@${profile.username} copied to clipboard.'))),
              const SizedBox(width: 9),
              Expanded(
                  child: PrimaryButton(
                      label: 'Share QR',
                      icon: AppIcons.share,
                      onPressed: () => _info(AppIcons.share, 'Share QR Card',
                          'Share your ScorchePay QR card via WhatsApp, Messages or Socials.'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _receiveBank() {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Bank name', 'ScorchePay MFB / Providus'),
          _detailRow('Account number', '8104562311'),
          _detailRow('Account name', 'Scorche Okafor'),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                  child: SecondaryButton(
                      label: 'Copy details',
                      icon: AppIcons.copy,
                      onPressed: () => _info(AppIcons.copy, 'Copied',
                          'Bank details copied to clipboard.'))),
              const SizedBox(width: 9),
              Expanded(
                  child: PrimaryButton(
                      label: 'Share',
                      icon: AppIcons.share,
                      onPressed: () => _info(AppIcons.share, 'Share',
                          'Share your reserved virtual bank details.'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _receiveCrypto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _NetworkChips(selected: 1),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            children: [
              Container(
                width: 160,
                height: 160,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child:
                    const Icon(AppIcons.qr, size: 100, color: Colors.black87),
              ),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(10)),
                child: const Text(
                  '0x8f2a51ce9d47b3a1f0c6e2d9b7a45c31e9c39c31',
                  style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                      child: SecondaryButton(
                          label: 'Copy address',
                          icon: AppIcons.copy,
                          onPressed: () => _info(AppIcons.copy, 'Copied',
                              'Wallet address copied to clipboard.'))),
                  const SizedBox(width: 9),
                  Expanded(
                      child: PrimaryButton(
                          label: 'Share',
                          icon: AppIcons.share,
                          onPressed: () => _info(AppIcons.share, 'Share',
                              'Share your crypto address to receive coins.'))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _receiveLink() {
    final profile = ref.watch(userProfileProvider);
    final slug = 'pay.scorche.app/${profile.username}';
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Personal Payment Link', style: AppText.cardTitle),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    slug,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _info(AppIcons.copy, 'Copied',
                      'Payment link copied to clipboard.'),
                  child: const Text('Copy',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Anyone with this link can pay you any amount from anywhere — cards, Apple Pay or bank transfer.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
              label: 'Share link',
              icon: AppIcons.share,
              onPressed: () => _info(AppIcons.share, 'Share',
                  'Share your payment link with customers or friends.')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // =======================================================
  // BILLS & UTILITIES
  // =======================================================

  Widget _bills() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: _iconGridInner([
            _GridEntry(
                AppIcons.phone,
                'Airtime',
                null,
                () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AirtimeScreen()))),
            _GridEntry(
                AppIcons.wifi,
                'Data',
                null,
                () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DataScreen()))),
            _GridEntry(
                AppIcons.bolt,
                'Electricity',
                null,
                () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const BillPaymentScreen(
                          icon: AppIcons.bolt,
                          title: 'Electricity',
                          subtitle: 'Instant token generation for meter recharge',
                          providers: [
                            'Ikeja Electric',
                            'Eko Electric',
                            'Abuja DisCo',
                            'PHED'
                          ],
                          idLabel: 'Meter number',
                          idHint: 'Enter your 11-digit meter number',
                        )))),
            _GridEntry(
                AppIcons.monitor,
                'Cable TV',
                null,
                () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const BillPaymentScreen(
                          icon: AppIcons.monitor,
                          title: 'Cable TV',
                          subtitle: 'Renew your subscription bouquet',
                          providers: ['DSTV', 'GOtv', 'Startimes'],
                          idLabel: 'Smart card / IUC number',
                          idHint: 'Enter your 10-digit smart card number',
                          packages: [
                            BillPackage('DSTV Padi', '₦4,400'),
                            BillPackage('DSTV Yanga', '₦6,000'),
                            BillPackage('DSTV Compact', '₦19,800'),
                            BillPackage('GOtv Max', '₦8,500'),
                          ],
                        )))),
            _GridEntry(
                AppIcons.globe,
                'Internet',
                null,
                () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const BillPaymentScreen(
                          icon: AppIcons.globe,
                          title: 'Internet',
                          subtitle: 'Spectranet, Smile, Starlink & fibre plans',
                          providers: ['Spectranet', 'Smile', 'MTN 5G WiFi', 'Starlink'],
                          idLabel: 'Account / Customer ID',
                          idHint: 'Enter your subscriber ID',
                        )))),
            _GridEntry(
                AppIcons.book,
                'Education',
                null,
                () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const BillPaymentScreen(
                          icon: AppIcons.book,
                          title: 'Education',
                          subtitle: 'WAEC, JAMB e-PIN and school fees',
                          providers: ['WAEC e-PIN', 'JAMB UTME', 'NECO'],
                          idLabel: 'Candidate / Registration ID',
                          idHint: 'Enter candidate registration number',
                          payLabel: 'Buy e-PIN',
                        )))),
            _GridEntry(
                AppIcons.chartBar,
                'Betting',
                null,
                () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const BillPaymentScreen(
                          icon: AppIcons.chartBar,
                          title: 'Betting',
                          subtitle: 'Instant funding for betting accounts',
                          providers: ['Bet9ja', 'SportyBet', '1xBet', 'Betway'],
                          idLabel: 'User Account ID',
                          idHint: 'Enter your betting account ID',
                          payLabel: 'Fund Wallet',
                        )))),
            _GridEntry(
                AppIcons.giftCard,
                'Gift Cards',
                null,
                () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GiftCardScreen()))),
          ]),
        ),
        const SectionTitle('Upcoming Bills'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              AppListRow(
                icon: AppIcons.bolt,
                title: 'Ikeja Electric',
                subtitle: 'Due in 2 days · Est. ₦12,000',
                tint: RowIconTint.warn,
                trailing: const StatusBadge(label: '₦12,000', tone: BadgeTone.warn),
              ),
              AppListRow(
                icon: AppIcons.monitor,
                title: 'DSTV Compact',
                subtitle: 'Due in 9 days',
                showDivider: false,
                trailing: const StatusBadge(label: '₦19,800', tone: BadgeTone.neutral),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =======================================================
  // ESCROW HUB
  // =======================================================

  Widget _escrow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PrimaryButton(
          label: 'Create new escrow',
          icon: AppIcons.plus,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateEscrowScreen()),
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              for (int i = 0; i < _escrowDeals.length; i++)
                AppListRow(
                  icon: _escrowDeals[i].icon,
                  title: _escrowDeals[i].title,
                  subtitle: '${_escrowDeals[i].subtitle} · ${_escrowDeals[i].amount}',
                  showDivider: i != _escrowDeals.length - 1,
                  trailing: StatusBadge(
                      label: _escrowDeals[i].status,
                      tone: _escrowDeals[i].tone),
                  onTap: () => _openEscrowDeal(_escrowDeals[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static const _escrowDeals = [
    _EscrowDeal(
        AppIcons.briefcase,
        'Freelance · Mobile UI App',
        'Milestone 2 of 3 in progress',
        'Active',
        BadgeTone.good,
        '@designer_kay',
        '₦180,000'),
    _EscrowDeal(
        AppIcons.building,
        'Vehicle Purchase · Toyota Camry',
        'Awaiting delivery photo proof',
        'Pending',
        BadgeTone.warn,
        '@auto_deals_ng',
        '₦4,200,000'),
    _EscrowDeal(
        AppIcons.package,
        'Marketplace · iPhone 16 Pro',
        'Funds released to seller',
        'Done',
        BadgeTone.neutral,
        '@techstore_ng',
        '₦950,000'),
    _EscrowDeal(
        AppIcons.building,
        'Property Deposit · Lekki Apt',
        'Dispute under review by arbitrator',
        'Dispute',
        BadgeTone.crit,
        '@realty_partners',
        '₦2,000,000'),
  ];

  void _openEscrowDeal(_EscrowDeal deal) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EscrowDetailScreen(
        title: deal.title,
        subtitle: deal.subtitle,
        statusLabel: deal.status,
        statusTone: deal.tone,
        counterparty: deal.counterparty,
        amount: deal.amount,
      ),
    ));
  }

  // =======================================================
  // MERCHANT & BUSINESS TOOLS
  // =======================================================

  Widget _merchant() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Expanded(child: _StatMini(label: "Today's Sales", value: '₦480,200')),
            SizedBox(width: 8),
            Expanded(child: _StatMini(label: 'Settlements', value: '₦2.1M', up: true)),
            SizedBox(width: 8),
            Expanded(child: _StatMini(label: 'Customers', value: '312')),
          ],
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Create an Invoice',
          icon: AppIcons.plus,
          onPressed: _openCreateInvoice,
        ),
        const SectionTitle('Merchant Tools'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              AppListRow(
                icon: AppIcons.qr,
                title: 'Merchant POS & Checkout QR',
                subtitle: 'Dynamic QR with audio payment chime',
                onTap: _openMerchantQr,
              ),
              AppListRow(
                icon: AppIcons.link,
                title: 'Payment Links & Storefronts',
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PayLinksScreen())),
              ),
              AppListRow(
                icon: AppIcons.receipt,
                title: 'Invoices & Customer Billing',
                onTap: _openCreateInvoice,
              ),
              AppListRow(
                icon: AppIcons.chartBar,
                title: 'Settlements & Sales Analytics',
                onTap: () => _openBook('analytics'),
              ),
              AppListRow(
                icon: AppIcons.shield,
                title: 'Business CAC Verification',
                subtitle: 'Upload registration docs & proof of address',
                showDivider: false,
                trailing: const StatusBadge(label: 'Verified', tone: BadgeTone.good),
                onTap: _openBusinessVerification,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openCreateInvoice() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreateFlowScreen(
        icon: AppIcons.receipt,
        title: 'New Merchant Invoice',
        subtitle: 'Add items, logo and send to client',
        fields: const [
          CreateField.text(label: 'Client Name / Business', hint: 'e.g. Acme Corp'),
          CreateField.text(label: 'Client Email', hint: 'billing@acme.com'),
          CreateField.text(label: 'Invoice Amount', hint: '0.00', prefixText: '₦ '),
          CreateField.text(label: 'Line Item Description', hint: 'e.g. 50x Branded T-Shirts'),
          CreateField.photo(label: 'Attach Business Logo / Invoice PDF (Device Photo)'),
          CreateField.text(label: 'Due Date', hint: 'e.g. 30 Sep 2026'),
        ],
        submitLabel: 'Generate & Send Invoice',
        successTitle: 'Invoice Created',
        successMessage: (v) => 'Invoice for ${v[2]} sent to ${v[0]} (${v[1]}). Shareable link ready.',
      ),
    ));
  }

  void _openBusinessVerification() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreateFlowScreen(
        icon: AppIcons.shield,
        title: 'Business Verification (KYC Tier 3)',
        subtitle: 'Upload CAC document and utility bill from device',
        fields: const [
          CreateField.text(label: 'Registered Business Name', hint: 'e.g. Scorche Global Ltd'),
          CreateField.text(label: 'CAC / RC Number', hint: 'e.g. RC 1894201'),
          CreateField.text(label: 'Tax Identification Number (TIN)', hint: 'e.g. 24890123-0001'),
          CreateField.photo(label: 'CAC Registration Certificate (Photo / Camera)'),
          CreateField.photo(label: 'Proof of Business Address / Utility Bill (Photo)'),
        ],
        submitLabel: 'Submit Business Documents',
        successTitle: 'Documents Submitted',
        successMessage: (v) => 'Business verification for "${v[0]}" (RC: ${v[1]}) is under review.',
      ),
    ));
  }

  void _openMerchantQr() {
    final amtCtrl = TextEditingController();
    showAppSheet(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Merchant POS Checkout', style: AppText.detailTitle),
          const SizedBox(height: 14),
          TextField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Charge Amount', hintText: '0.00', prefixText: '₦ '),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Icon(AppIcons.qr, size: 140, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          const Text('Scan to pay with ScorchePay, USSD or Bank App', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Generate New QR',
            onPressed: () {
              Navigator.of(ctx).pop();
              showAppModal(context, icon: AppIcons.qr, title: 'POS QR Active', message: 'Dynamic payment QR displayed for customer.');
            },
          ),
        ],
      ),
    );
  }

  Widget _business() => _merchant();

  // =======================================================
  // CROSS-BORDER PAYMENTS
  // =======================================================

  Widget _crossBorder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('From', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('To', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      FlagChip(flag: CountryFlag.ng),
                      SizedBox(width: 7),
                      Text('NGN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                    ],
                  ),
                  const Icon(AppIcons.arrowUpRight, size: 16, color: AppColors.muted),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      FlagChip(flag: CountryFlag.us),
                      SizedBox(width: 7),
                      Text('USD', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('1 USD ≈ 1,545.20 NGN · Guaranteed rate (14:59 lock)', style: TextStyle(fontSize: 12, color: AppColors.gain, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Send Cross-Border Transfer',
                icon: AppIcons.globe,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CreateFlowScreen(
                    icon: AppIcons.globe,
                    title: 'Cross-Border Transfer',
                    subtitle: 'Send internationally with instant delivery',
                    fields: const [
                      CreateField.text(label: 'Beneficiary Name', hint: 'Full legal name'),
                      CreateField.chips(label: 'Destination Currency', chips: ['USD', 'GBP', 'EUR', 'GHS', 'KES']),
                      CreateField.text(label: 'Transfer Amount', hint: '0.00'),
                      CreateField.chips(label: 'Delivery Method', chips: ['Direct Bank Deposit', 'Mobile Money (M-Pesa / MoMo)', 'Cash Pickup']),
                      CreateField.text(label: 'Account / Mobile Number', hint: 'IBAN, Routing or Mobile No'),
                    ],
                    submitLabel: 'Execute Cross-Border Transfer',
                    successTitle: 'Transfer Initiated',
                    successMessage: (v) => '${v[2]} sent to ${v[0]} via ${v[3]}. Funds arriving in <15 mins.',
                  ),
                )),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =======================================================
  // AUTOMATION ENGINE
  // =======================================================

  Widget _automation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              for (int i = 0; i < _automationToggles.length; i++)
                _ToggleRow(
                  icon: AppIcons.gear,
                  title: _automationToggles.keys.elementAt(i),
                  value: _automationToggles.values.elementAt(i),
                  showDivider: i != _automationToggles.length - 1,
                  onChanged: (v) => setState(() =>
                      _automationToggles[_automationToggles.keys.elementAt(i)] = v),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SecondaryButton(
          label: 'Create new automation rule',
          icon: AppIcons.plus,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CreateFlowScreen(
              icon: AppIcons.gear,
              title: 'New Automation Rule',
              subtitle: 'Select trigger condition and automated action',
              fields: const [
                CreateField.chips(label: 'When this happens (Trigger)', chips: [
                  'On money received',
                  'Every Friday at 6 PM',
                  'When bill due in 2 days',
                  'Balance drops below ₦10,000'
                ]),
                CreateField.chips(label: 'Do this automatically (Action)', chips: [
                  'Auto-save 10% to Goal',
                  'Auto-convert to USDT',
                  'Auto-pay utility bill',
                  'Sweep excess balance'
                ]),
                CreateField.text(label: 'Amount / Percentage (Optional)', hint: 'e.g. 10000 or 10%'),
              ],
              submitLabel: 'Activate Rule',
              successTitle: 'Automation Rule Created',
              successMessage: (v) => '"${v[0]}" → "${v[1]}" is now active and monitoring your account.',
            ),
          )),
        ),
      ],
    );
  }

  // =======================================================
  // TRANSACTIONS & RECEIPTS
  // =======================================================

  static const _transactionsTabs = ['All', 'Money', 'Crypto', 'Bills', 'Escrow'];

  Widget _transactions() {
    final items = _transactionsTab == 0
        ? MockData.activity
        : MockData.activity
            .where((a) => a.category == ActivityCategory.values[_transactionsTab - 1])
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TabBar(
            tabs: _transactionsTabs,
            selected: _transactionsTab,
            onChanged: (i) => setState(() => _transactionsTab = i)),
        _searchField(icon: AppIcons.search, hint: 'Search transaction reference or contact'),
        const SizedBox(height: 6),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++)
                AppListRow(
                  icon: items[i].icon,
                  title: items[i].title,
                  subtitle: items[i].subtitle,
                  showDivider: i != items.length - 1,
                  trailing: Text(
                    items[i].amount,
                    style: AppText.tabular.copyWith(
                      fontWeight: FontWeight.w800,
                      color: items[i].isCredit ? AppColors.gain : AppColors.textPrimary,
                    ),
                  ),
                  onTap: () => _openTransactionReceipt(items[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _openTransactionReceipt(ActivityItem item) {
    showAppSheet(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: item.isCredit ? AppColors.statusSoft(AppColors.gain) : AppColors.surface3,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 24, color: item.isCredit ? AppColors.gain : AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(item.amount, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(item.title, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 20),
          _detailRow('Transaction Date', item.subtitle),
          _detailRow('Transaction ID', 'TXN_${item.title.hashCode.abs()}'),
          _detailRow('Status', 'Successful / Settled'),
          _detailRow('Payment Rail', 'ScorchePay Money OS Core'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Share Receipt',
                  icon: AppIcons.share,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _info(AppIcons.share, 'Receipt Shared', 'Transaction receipt exported as PDF.');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  label: 'Done',
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =======================================================
  // SECURITY & PRIVACY
  // =======================================================

  Widget _security() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              for (int i = 0; i < _securityToggles.length; i++)
                _ToggleRow(
                  icon: const [
                    AppIcons.key,
                    AppIcons.fingerprint,
                    AppIcons.shield,
                    AppIcons.monitor,
                    AppIcons.mail,
                    AppIcons.lock
                  ][i % 6],
                  title: _securityToggles.keys.elementAt(i),
                  value: _securityToggles.values.elementAt(i),
                  showDivider: i != _securityToggles.length - 1,
                  onChanged: (v) => setState(() =>
                      _securityToggles[_securityToggles.keys.elementAt(i)] = v),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Change Transaction PIN',
          icon: AppIcons.key,
          onPressed: _openChangePinModal,
        ),
      ],
    );
  }

  void _openChangePinModal() {
    final oldPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();

    showAppSheet(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Change Security PIN', style: AppText.detailTitle),
          const SizedBox(height: 14),
          TextField(
            controller: oldPinCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Current 4-digit PIN'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: newPinCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'New 4-digit PIN'),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Update Security PIN',
            onPressed: () {
              if (oldPinCtrl.text.length == 4 && newPinCtrl.text.length == 4) {
                Navigator.of(ctx).pop();
                showAppModal(
                  context,
                  icon: AppIcons.check,
                  iconColor: AppColors.gain,
                  title: 'PIN Updated',
                  message: 'Your 4-digit security PIN has been updated successfully.',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // =======================================================
  // NOTIFICATIONS
  // =======================================================

  Widget _notifications() {
    const items = [
      _GridEntry(AppIcons.receive, 'Received ₦85,000 from @ada_b', '2h ago'),
      _GridEntry(AppIcons.bolt, 'Smart Pay: MTN Data 5GB — successful', '5h ago'),
      _GridEntry(AppIcons.coins, 'BTC price alert: Bitcoin crossed \$96,000', '8h ago'),
      _GridEntry(AppIcons.shield, 'Escrow: buyer requested proof of delivery', '1d ago'),
      _GridEntry(AppIcons.bill, 'Electricity bill due in 2 days', '1d ago'),
      _GridEntry(AppIcons.target, 'Savings goal "New Car" is 68% funded', '2d ago'),
      _GridEntry(AppIcons.lock, 'New login from Chrome on macOS', '3d ago'),
      _GridEntry(AppIcons.trophy, 'You earned ₦5,000 referral cashback', '4d ago'),
    ];
    return Column(
      children: [
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++)
                AppListRow(
                  icon: items[i].icon,
                  title: items[i].label,
                  subtitle: items[i].sub,
                  showChevron: false,
                  showDivider: i != items.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }

  // =======================================================
  // DEVELOPER PLATFORM
  // =======================================================

  Widget _developer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Live API Key',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => _info(AppIcons.copy, 'Copied',
                        'Live API key copied to clipboard.'),
                    child: const Text('Copy Key',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _CodeBlock('sk_live_5c9f918237482910ae21'),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              AppListRow(
                icon: AppIcons.webhook,
                title: 'Webhook Endpoints',
                subtitle: 'https://api.merchant.com/webhook',
                onTap: _openWebhookConfig,
              ),
              const AppListRow(icon: AppIcons.code, title: 'Sandbox Environment', subtitle: 'Test keys active', showChevron: false),
              const AppListRow(icon: AppIcons.package, title: 'SDK Libraries', subtitle: 'Flutter · Node · Python · Go', showChevron: false),
              const AppListRow(icon: AppIcons.book, title: 'API Documentation', subtitle: 'RESTful API v2 specs', showDivider: false),
            ],
          ),
        ),
      ],
    );
  }

  void _openWebhookConfig() {
    final urlCtrl = TextEditingController(text: 'https://api.merchant.com/webhook');
    showAppSheet(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Configure Webhooks', style: AppText.detailTitle),
          const SizedBox(height: 14),
          TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Webhook URL Endpoint')),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Save Endpoint',
            onPressed: () {
              Navigator.of(ctx).pop();
              showAppModal(context, icon: AppIcons.check, title: 'Webhook Saved', message: 'Webhook endpoint updated.');
            },
          ),
        ],
      ),
    );
  }

  // =======================================================
  // HELPERS & COMMON WIDGETS
  // =======================================================

  Widget _searchField(
      {required IconData icon,
      required String hint,
      TextEditingController? controller,
      ValueChanged<String>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: AppColors.muted),
        ),
      ),
    );
  }

  Widget _iconGrid(List<_GridEntry> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _iconGridInner(items),
    );
  }

  Widget _iconGridInner(List<_GridEntry> items) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 4,
      childAspectRatio: 0.86,
      children: [
        for (final it in items)
          IconActionButton(
              icon: it.icon,
              label: it.label,
              size: 44,
              onTap: it.onTap ?? () {}),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.book});

  final BookItem book;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconCircleButton(
            icon: AppIcons.chevronLeft,
            onTap: () => Navigator.of(context).pop()),
        const SizedBox(width: 12),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(book.icon, size: 19, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(book.title, style: AppText.detailTitle),
              const SizedBox(height: 1),
              Text(book.blurb,
                  style: AppText.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tabs, this.selected = 0, this.onChanged});

  final List<String> tabs;
  final int selected;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: AppColors.surface2, borderRadius: BorderRadius.circular(13)),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: onChanged == null ? null : () => onChanged!(i),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  margin: EdgeInsets.only(right: i != tabs.length - 1 ? 2 : 0),
                  decoration: BoxDecoration(
                    color: i == selected ? AppColors.surface3 : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tabs[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: i == selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({required this.label, required this.value, this.up = false});

  final String label;
  final String value;
  final bool up;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: up ? AppColors.gain : AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.hairline))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AppText.body)),
          AppToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _StackAvatars extends StatelessWidget {
  const _StackAvatars({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    const itemWidth = 24.0;
    const overlap = 8.0;
    final totalWidth = itemWidth + (labels.length - 1) * (itemWidth - overlap);

    return SizedBox(
      width: totalWidth,
      height: itemWidth,
      child: Stack(
        children: [
          for (int i = 0; i < labels.length; i++)
            Positioned(
              left: i * (itemWidth - overlap),
              child: Container(
                width: itemWidth,
                height: itemWidth,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface3,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock(this.code);

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        code,
        style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: AppColors.gain,
            height: 1.65),
      ),
    );
  }
}

class _NetworkChips extends StatelessWidget {
  const _NetworkChips({this.selected = 0});

  final int selected;

  static const _networks = ['Bitcoin', 'Ethereum', 'USDT · TRC20', 'Solana'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < _networks.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: i == selected ? AppColors.accentSoft : AppColors.surface2,
              border: Border.all(
                  color: i == selected
                      ? AppColors.accent.withOpacity(0.4)
                      : AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _networks[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    i == selected ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _GridEntry {
  const _GridEntry(this.icon, this.label, [this.sub, this.onTap]);

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? sub;
}

class _EscrowDeal {
  const _EscrowDeal(this.icon, this.title, this.subtitle, this.status,
      this.tone, this.counterparty, this.amount);

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final BadgeTone tone;
  final String counterparty;
  final String amount;
}

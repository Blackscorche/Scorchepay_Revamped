import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_toggle.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/charts/simple_bar_chart.dart';
import '../../core/widgets/flag_chip.dart';
import '../../core/widgets/list_row.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// Generic "book" detail screen — one screen definition drives all ~19
/// roadmap items via [BookType], mirroring renderBookDetail() in the
/// HTML prototype (every switch case translated 1:1).
class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final Map<String, bool> _automationToggles = {
    'Round-up savings': true,
    'Auto-pay electricity': true,
    'Weekly auto-save ₦10,000': true,
    'Auto-convert USDT → NGN on receipt': false,
  };

  final Map<String, bool> _securityToggles = {
    'PIN': true,
    'Biometrics (Face / Touch ID)': true,
    '2FA authentication': true,
    'Device management': false,
    'Trusted devices': true,
    'Login alerts': true,
  };

  void _openBook(String id) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: id)));
  }

  void _info(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final book = MockData.bookById(widget.bookId)!;
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
      case BookType.savings:
        return _savings();
      case BookType.group:
        return _group();
      case BookType.transactions:
        return _transactions();
      case BookType.insights:
        return _insights();
      case BookType.ai:
        return _ai();
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

  Widget _send() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TabBar(tabs: ['Username', 'QR', 'Bank', 'Address', 'Saved']),
        _searchField(icon: AppIcons.user, hint: '@username or search contacts'),
        const SizedBox(height: 6),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: const [
              AppListRow(icon: AppIcons.user, title: '@ada_b', subtitle: 'Recent contact', showChevron: false),
              AppListRow(icon: AppIcons.user, title: '@chidi.eth', subtitle: 'Recent contact', showChevron: false),
              AppListRow(icon: AppIcons.user, title: '@nomsa', subtitle: 'Recent contact', showChevron: false),
              AppListRow(icon: AppIcons.user, title: '@kwame_gh', subtitle: 'Recent contact', showChevron: false, showDivider: false),
            ],
          ),
        ),
        const SectionTitle('More ways to send'),
        _iconGrid(const [
          _GridEntry(AppIcons.calendar, 'Scheduled'),
          _GridEntry(AppIcons.repeat, 'Recurring'),
          _GridEntry(AppIcons.receipt, 'Requests'),
          _GridEntry(AppIcons.link, 'Pay Links'),
          _GridEntry(AppIcons.package, 'Split Bill'),
          _GridEntry(AppIcons.package, 'Bulk'),
        ]),
      ],
    );
  }

  Widget _receive() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TabBar(tabs: ['Username', 'Bank', 'Crypto', 'Link']),
        AppCard(
          child: Column(
            children: [
              Container(
                width: 180,
                height: 180,
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: const Icon(AppIcons.qr, size: 120, color: Colors.black87),
              ),
              const Text('@scorche', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
              const SizedBox(height: 3),
              const Text('Universal QR · bank, wallet & crypto', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: SecondaryButton(label: 'Copy', icon: AppIcons.copy, onPressed: () => _info('Copied to clipboard.'))),
                  const SizedBox(width: 9),
                  Expanded(child: PrimaryButton(label: 'Share', icon: AppIcons.share, onPressed: () => _info('Share sheet opened.'))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bills() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: _iconGridInner(const [
            _GridEntry(AppIcons.bill, 'Airtime'),
            _GridEntry(AppIcons.bill, 'Data'),
            _GridEntry(AppIcons.bolt, 'Electricity'),
            _GridEntry(AppIcons.monitor, 'Cable TV'),
            _GridEntry(AppIcons.globe, 'Internet'),
            _GridEntry(AppIcons.book, 'Education'),
            _GridEntry(AppIcons.chartBar, 'Betting'),
            _GridEntry(AppIcons.package, 'Gift Cards'),
          ]),
        ),
        const SectionTitle('Upcoming'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              AppListRow(
                icon: AppIcons.bolt,
                title: 'Ikeja Electric',
                subtitle: 'Due in 2 days',
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

  Widget _escrow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PrimaryButton(label: 'Create new escrow', icon: AppIcons.plus, onPressed: () => _info('Escrow creation flow started.')),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: const [
              AppListRow(
                icon: AppIcons.briefcase,
                title: 'Freelance · Web design',
                subtitle: 'Milestone 2 of 3',
                trailing: StatusBadge(label: 'Active', tone: BadgeTone.good),
              ),
              AppListRow(
                icon: AppIcons.building,
                title: 'Vehicle purchase',
                subtitle: 'Awaiting delivery proof',
                trailing: StatusBadge(label: 'Pending', tone: BadgeTone.warn),
              ),
              AppListRow(
                icon: AppIcons.package,
                title: 'Marketplace · iPhone 16',
                subtitle: 'Funds released',
                trailing: StatusBadge(label: 'Done', tone: BadgeTone.neutral),
              ),
              AppListRow(
                icon: AppIcons.building,
                title: 'Property deposit',
                subtitle: 'Dispute opened',
                showDivider: false,
                trailing: StatusBadge(label: 'Dispute', tone: BadgeTone.crit),
              ),
            ],
          ),
        ),
        const SectionTitle('Escrow types'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              for (final t in const ['Marketplace', 'Freelancer', 'Business', 'Property', 'Vehicle', 'Digital goods'])
                AppListRow(icon: AppIcons.shield, title: t, showDivider: t != 'Digital goods'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _merchant() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Expanded(child: _StatMini(label: "Today's sales", value: '₦480,200')),
            SizedBox(width: 8),
            Expanded(child: _StatMini(label: 'Settlements', value: '₦2.1M', up: true)),
            SizedBox(width: 8),
            Expanded(child: _StatMini(label: 'Customers', value: '312')),
          ],
        ),
        const SectionTitle('Tools'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              const AppListRow(icon: AppIcons.qr, title: 'Merchant QR code', showChevron: false),
              const AppListRow(icon: AppIcons.link, title: 'Payment links & pages', showChevron: false),
              const AppListRow(icon: AppIcons.receipt, title: 'Invoices', showChevron: false),
              AppListRow(icon: AppIcons.chartBar, title: 'Analytics', onTap: () => _openBook('analytics')),
              const AppListRow(
                icon: AppIcons.shield,
                title: 'Merchant verification',
                showDivider: false,
                trailing: StatusBadge(label: 'Verified', tone: BadgeTone.good),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
                      Text('NGN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                    ],
                  ),
                  const Icon(AppIcons.arrowUpRight, size: 16, color: AppColors.muted),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      FlagChip(flag: CountryFlag.us),
                      SizedBox(width: 7),
                      Text('USD', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('1 USD ≈ 1,545.20 NGN · live rate', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 14),
              PrimaryButton(label: 'Send cross-border', onPressed: () => _info('Cross-border transfer flow started.')),
            ],
          ),
        ),
        const SectionTitle('Corridors'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              for (final c in const ['NGN → USD', 'NGN → GHS', 'GHS → NGN', 'USD → EUR', 'GBP → NGN'])
                AppListRow(icon: AppIcons.globe, title: c, showDivider: c != 'GBP → NGN'),
            ],
          ),
        ),
      ],
    );
  }

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
                  onChanged: (v) => setState(() => _automationToggles[_automationToggles.keys.elementAt(i)] = v),
                ),
            ],
          ),
        ),
        SecondaryButton(label: 'Create new rule', icon: AppIcons.plus, onPressed: () => _info('New automation rule flow started.')),
      ],
    );
  }

  Widget _savings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in MockData.savingsGoals)
          AppCard(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
                          child: Icon(g.icon, size: 15, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Text(g.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary)),
                      ],
                    ),
                    StatusBadge(label: g.tag, tone: _goalTone(g.tagColor)),
                  ],
                ),
                const SizedBox(height: 9),
                AppProgressBar(value: g.progress),
                const SizedBox(height: 9),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${g.saved} saved', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text('${(g.progress * 100).round()}% of ${g.target}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        SecondaryButton(label: 'New savings goal', icon: AppIcons.plus, onPressed: () => _info('New savings goal flow started.')),
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
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Family House Fund', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary)),
                  _StackAvatars(labels: ['A', 'B', 'C', '+4']),
                ],
              ),
              const SizedBox(height: 9),
              const AppProgressBar(value: 0.54, color: AppColors.info),
              const SizedBox(height: 9),
              const Text('₦2.16M of ₦4M · 7 members', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Squad Trip 2027', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary)),
                  _StackAvatars(labels: ['K', 'N', 'T']),
                ],
              ),
              const SizedBox(height: 9),
              const AppProgressBar(value: 0.22, color: AppColors.gain),
              const SizedBox(height: 9),
              const Text('\$440 of \$2,000 · 3 members', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        SecondaryButton(label: 'Start a group goal', icon: AppIcons.plus, onPressed: () => _info('New group goal flow started.')),
      ],
    );
  }

  Widget _transactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TabBar(tabs: ['All', 'Money', 'Crypto', 'Bills', 'Escrow']),
        _searchField(icon: AppIcons.search, hint: 'Search transactions'),
        const SizedBox(height: 6),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              for (int i = 0; i < MockData.activity.length; i++)
                AppListRow(
                  icon: MockData.activity[i].icon,
                  title: MockData.activity[i].title,
                  subtitle: MockData.activity[i].subtitle,
                  showDivider: i != MockData.activity.length - 1,
                  trailing: Text(
                    MockData.activity[i].amount,
                    style: AppText.tabular.copyWith(
                      fontWeight: FontWeight.w700,
                      color: MockData.activity[i].isCredit ? AppColors.gain : AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SecondaryButton(label: 'Export statement (CSV / PDF)', icon: AppIcons.download, onPressed: () => _info('Preparing export…')),
      ],
    );
  }

  Widget _insights() {
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
                  Text('Spending by category', style: AppText.cardTitle),
                  Text('This month', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),
              const SimpleBarChart(data: [
                BarDatum('Bills', 62, AppColors.catBlue),
                BarDatum('Data', 88, AppColors.catOrange),
                BarDatum('Food', 45, AppColors.catAqua),
                BarDatum('Crypto', 30, AppColors.catYellow),
                BarDatum('Transport', 54, AppColors.catMagenta),
                BarDatum('Other', 20, AppColors.catGreen),
              ]),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: const [
              AppListRow(
                icon: AppIcons.target,
                title: 'Financial health score',
                subtitle: 'Good standing',
                trailing: StatusBadge(label: '78/100', tone: BadgeTone.good),
              ),
              AppListRow(icon: AppIcons.chartLine, title: 'Cash flow report', subtitle: 'Income vs. expenses', showChevron: false),
              AppListRow(icon: AppIcons.calendar, title: 'Monthly & yearly reports', showChevron: false),
              AppListRow(icon: AppIcons.chartBar, title: 'Budget tracking', showChevron: false, showDivider: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ai() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Bubble(text: 'You\'re on track to hit your "New Car" goal 3 weeks early if you keep this pace.', accent: true),
        const _Bubble(text: 'Your Data spend is up 23% this month. Want me to suggest a cheaper plan?'),
        const _Bubble(text: 'I flagged an unusual login from a new device — was that you?'),
        const _Bubble(text: 'You could save ₦8,400/mo by moving idle NGN into stablecoin savings at 14% APY.'),
        const SizedBox(height: 6),
        _searchField(icon: AppIcons.sparkle, hint: 'Ask your AI assistant anything...'),
      ],
    );
  }

  Widget _rewards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassHeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('Loyalty tier'),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(AppIcons.trophy, size: 24, color: AppColors.textPrimary),
                  SizedBox(width: 8),
                  Text('Silver', style: AppText.heroNumberMedium),
                ],
              ),
              const SizedBox(height: 12),
              const AppProgressBar(value: 0.64),
              const SizedBox(height: 9),
              const Text('640 / 1,000 pts to Gold', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your referral code', style: AppText.cardTitle),
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
                    const Text('SCORCHE-3F9K', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textPrimary)),
                    GestureDetector(
                      onTap: () => _info('Referral code copied!'),
                      child: const Text('Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text('Earn ₦5,000 per friend who signs up & funds their wallet.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: const [
              AppListRow(
                icon: AppIcons.coins,
                title: 'Cashback earned',
                subtitle: 'This month',
                showChevron: false,
                trailing: Text('₦4,120', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary)),
              ),
              AppListRow(icon: AppIcons.trophy, title: 'Achievements', subtitle: '12 unlocked', showChevron: false, showDivider: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderStrong),
                ),
                alignment: Alignment.center,
                child: const Text('SC', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19, color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 12),
              const Text('Scorche', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 3),
              const Text('@scorche · issaabu399@gmail.com', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 10),
              const StatusBadge(label: 'KYC Verified — Tier 3', tone: BadgeTone.good),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              const AppListRow(icon: AppIcons.idCard, title: 'Verification & KYC', showChevron: false),
              AppListRow(icon: AppIcons.globe, title: 'Preferred currency', subtitle: 'NGN', onTap: () => _openBook('multicurrency')),
              const AppListRow(icon: AppIcons.globe, title: 'Language', subtitle: 'English', showChevron: false),
              AppListRow(icon: AppIcons.bell, title: 'Notification preferences', onTap: () => _openBook('notifications')),
              AppListRow(icon: AppIcons.lock, title: 'Security', onTap: () => _openBook('security')),
              AppListRow(icon: AppIcons.trophy, title: 'Referral code', showDivider: false, onTap: () => _openBook('rewards')),
            ],
          ),
        ),
      ],
    );
  }

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
                  icon: const [AppIcons.key, AppIcons.fingerprint, AppIcons.monitor, AppIcons.monitor, AppIcons.shield, AppIcons.mail][i],
                  title: _securityToggles.keys.elementAt(i),
                  value: _securityToggles.values.elementAt(i),
                  showDivider: i != _securityToggles.length - 1,
                  onChanged: (v) => setState(() => _securityToggles[_securityToggles.keys.elementAt(i)] = v),
                ),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: const [
              AppListRow(icon: AppIcons.check, title: 'Transaction confirmation', subtitle: 'Required above ₦50,000', showChevron: false),
              AppListRow(
                icon: AppIcons.shield,
                title: 'Fraud detection',
                subtitle: 'AI-monitored, active',
                showChevron: false,
                trailing: StatusBadge(label: 'Active', tone: BadgeTone.good),
              ),
              AppListRow(icon: AppIcons.book, title: 'Audit logs', showChevron: false, showDivider: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _notifications() {
    const items = [
      _GridEntry(AppIcons.receive, 'Received ₦85,000 from @ada_b', '2h ago'),
      _GridEntry(AppIcons.bolt, 'Smart Pay: MTN Data — successful', '5h ago'),
      _GridEntry(AppIcons.coins, 'BTC price alert: crossed \$96,000', '8h ago'),
      _GridEntry(AppIcons.shield, 'Escrow: buyer requested proof of delivery', '1d ago'),
      _GridEntry(AppIcons.bill, 'Electricity bill due in 2 days', '1d ago'),
      _GridEntry(AppIcons.target, 'Savings goal "New Car" is 68% funded', '2d ago'),
      _GridEntry(AppIcons.lock, 'New login from Chrome on Windows', '3d ago'),
      _GridEntry(AppIcons.trophy, 'You earned ₦5,000 cashback', '4d ago'),
    ];
    return AppCard(
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
    );
  }

  Widget _business() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: [
              const AppListRow(
                icon: AppIcons.receipt,
                title: 'Invoice #1042 · Acme Ltd',
                subtitle: 'Due Aug 25',
                showChevron: false,
                trailing: StatusBadge(label: 'Unpaid', tone: BadgeTone.warn),
              ),
              const AppListRow(
                icon: AppIcons.receipt,
                title: 'Invoice #1041 · Nomsa K.',
                subtitle: 'Paid Aug 12',
                showChevron: false,
                trailing: StatusBadge(label: 'Paid', tone: BadgeTone.good),
              ),
              const AppListRow(icon: AppIcons.link, title: 'Payment pages & links', showChevron: false),
              AppListRow(icon: AppIcons.chartBar, title: 'Settlements & analytics', onTap: () => _openBook('analytics')),
              const AppListRow(
                icon: AppIcons.shield,
                title: 'Business verification',
                showDivider: false,
                trailing: StatusBadge(label: 'Verified', tone: BadgeTone.good),
              ),
            ],
          ),
        ),
        PrimaryButton(label: 'Create invoice', icon: AppIcons.plus, onPressed: () => _info('Invoice creation flow started.')),
      ],
    );
  }

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
                  const Text('Live API key', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => _info('API key copied!'),
                    child: const Text('Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _CodeBlock('sk_live_5c9f••••••••••••ae21'),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Column(
            children: const [
              AppListRow(icon: AppIcons.webhook, title: 'Webhooks', showChevron: false),
              AppListRow(icon: AppIcons.code, title: 'Sandbox environment', showChevron: false),
              AppListRow(icon: AppIcons.package, title: 'SDKs', subtitle: 'Node · Python · PHP', showChevron: false),
              AppListRow(icon: AppIcons.book, title: 'Documentation', showChevron: false, showDivider: false),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: const _CodeBlock('POST /v1/payments\n{\n  "amount": 24500,\n  "currency": "auto",\n  "recipient": "@ada_b"\n}'),
        ),
      ],
    );
  }

  Widget _searchField({required IconData icon, required String hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: TextField(
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
      mainAxisSpacing: 16,
      crossAxisSpacing: 6,
      childAspectRatio: 0.82,
      children: [
        for (final it in items) _ServiceIcon(icon: it.icon, label: it.label),
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
        IconCircleButton(icon: AppIcons.chevronLeft, onTap: () => Navigator.of(context).pop()),
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
              Text(book.blurb, style: AppText.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tabs});

  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(13)),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                margin: EdgeInsets.only(right: i != tabs.length - 1 ? 2 : 0),
                decoration: BoxDecoration(
                  color: i == 0 ? AppColors.surface3 : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: i == 0 ? AppColors.textPrimary : AppColors.textSecondary,
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
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: up ? AppColors.gain : AppColors.textPrimary)),
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
        border: showDivider ? const Border(bottom: BorderSide(color: AppColors.hairline)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < labels.length; i++)
          Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : -8),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface3,
              border: Border.all(color: AppColors.surface, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(labels[i], style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, this.accent = false});

  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: accent ? AppColors.accentSoft : AppColors.surface2,
        border: Border.all(color: accent ? AppColors.accent.withOpacity(0.22) : AppColors.hairline),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12.5, height: 1.55, color: AppColors.textPrimary)),
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
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.gain, height: 1.65),
      ),
    );
  }
}

class _ServiceIcon extends StatelessWidget {
  const _ServiceIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: 19, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 7),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ],
    );
  }
}

class _GridEntry {
  const _GridEntry(this.icon, this.label, [this.sub]);

  final IconData icon;
  final String label;
  final String? sub;
}

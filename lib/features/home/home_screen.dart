import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/widgets/scorch_mascot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/charts/wealth_line_chart.dart';
import '../../core/widgets/decorative_rings.dart';
import '../../core/widgets/flag_chip.dart';
import '../../core/widgets/icon_action_button.dart';
import '../../core/widgets/list_row.dart';
import '../../core/widgets/section_title.dart';
import '../../data/mock_data.dart';
import '../../state/models/ledger_entry.dart';
import '../../state/providers/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../bills/airtime_screen.dart';
import '../bills/data_screen.dart';
import '../crypto/crypto_screen.dart';
import '../flows/escrow/escrow_list_screen.dart';
import '../flows/send/send_recipient_screen.dart';
import '../more/book_detail_screen.dart';
import '../smart_pay/smart_pay_screen.dart';

/// Home tab — wealth hero, quick actions, attention items, smart
/// insights, recent activity, services grid and announcements. Mirrors
/// renderHome() in the HTML prototype.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hideBalance = false;
  int _currencyIndex = 0;

  void _openBook(String id) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: id)));
  }

  void _pickCurrency() {
    showAppSheet<void>(
      context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('View balance in', style: AppText.detailTitle),
          const SizedBox(height: 4),
          for (int i = 0; i < _currencyOptions.length; i++)
            _CurrencyRow(
              option: _currencyOptions[i],
              selected: i == _currencyIndex,
              showDivider: i != _currencyOptions.length - 1,
              onTap: () {
                setState(() => _currencyIndex = i);
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
      children: [
        _TopBar(
          onBell: () => _openBook('notifications'),
          onProfile: () => _openBook('profile'),
        ),

        const ScorchCompanion(activity: ScorchActivity.welcome, title: 'A little spark for your day', message: 'Meet Scorch. Your money companion, every step of the way.'),
        GlassHeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Eyebrow('Total balance'),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickCurrency,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 4, 9, 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            border: Border.all(color: AppColors.borderStrong),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_currencyOptions[_currencyIndex].code,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary)),
                              Icon(AppIcons.chevronDown,
                                  size: 13, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _hideBalance = !_hideBalance),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                              _hideBalance ? AppIcons.eyeOff : AppIcons.eye,
                              size: 17,
                              color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ImageFiltered(
                imageFilter: ImageFilter.blur(
                    sigmaX: _hideBalance ? 8 : 0, sigmaY: _hideBalance ? 8 : 0),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                          text: _currencyOptions[_currencyIndex].symbol,
                          style: AppText.heroNumberMedium.copyWith(
                              color: AppColors.textSecondary, fontSize: 24)),
                      TextSpan(
                          text: _currencyOptions[_currencyIndex].amount,
                          style: AppText.heroNumber),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 3),
              ImageFiltered(
                imageFilter: ImageFilter.blur(
                    sigmaX: _hideBalance ? 8 : 0, sigmaY: _hideBalance ? 8 : 0),
                child: Text(_currencyOptions[_currencyIndex].equivalent,
                    style: TextStyle(
                        fontSize: 12.5, color: AppColors.muted)),
              ),
              const SizedBox(height: 11),
              const Row(
                children: [
                  Icon(AppIcons.arrowUpRight, size: 13, color: AppColors.gain),
                  SizedBox(width: 5),
                  Text('+2.4% today',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gain)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(
                      child:
                          _StatMini(label: 'Today', value: '+2.4%', up: true)),
                  SizedBox(width: 8),
                  Expanded(
                      child: _StatMini(
                          label: 'This week', value: '+6.1%', up: true)),
                  SizedBox(width: 8),
                  Expanded(
                      child: _StatMini(
                          label: 'This month', value: '−1.8%', up: false)),
                ],
              ),
              const SizedBox(height: 16),
              WealthLineChart(points: MockData.wealthTrend),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('6d ago',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted)),
                  Text('4d',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted)),
                  Text('2d',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted)),
                  Text('Today',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: IconActionButton(
                icon: AppIcons.bolt,
                label: 'Smart Pay',
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SmartPayScreen())),
              ),
            ),
            Expanded(
              child: IconActionButton(
                  icon: AppIcons.send,
                  label: 'Send',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SendRecipientScreen()))),
            ),
            Expanded(
              child: IconActionButton(
                  icon: AppIcons.receive,
                  label: 'Receive',
                  onTap: () => _openBook('receive')),
            ),
            Expanded(
              child: IconActionButton(
                icon: AppIcons.coins,
                label: 'Crypto',
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CryptoScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
          child: Column(
            children: [
              const _CardHeader(
                  icon: AppIcons.bell, title: 'Needs your attention'),
              AppListRow(
                icon: AppIcons.bill,
                title: 'Electricity bill due in 2 days',
                subtitle: 'Est. ₦12,000 · Ikeja Electric',
                tint: RowIconTint.warn,
                onTap: () => _openBook('bills'),
              ),
              AppListRow(
                icon: AppIcons.shield,
                title: 'Escrow action required',
                subtitle: 'Buyer requested delivery proof',
                tint: RowIconTint.warn,
                showDivider: false,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const EscrowListScreen())),
              ),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
          child: Column(
            children: [
              const _CardHeader(
                  icon: AppIcons.sparkle, title: 'Smart insights'),
              AppListRow(
                icon: AppIcons.chartBar,
                title: 'You spent 23% more on Data this month',
                subtitle: 'Compared to your 3-month average',
                onTap: () => _openBook('insights'),
              ),
              AppListRow(
                icon: AppIcons.target,
                title: '"New Car" goal is 68% funded',
                subtitle: '₦12,000/week keeps you on track',
                showDivider: false,
                onTap: () => _openBook('savings'),
              ),
            ],
          ),
        ),
        SectionTitle('Recent activity',
            action: 'See all', onAction: () => _openBook('transactions')),
        Consumer(
          builder: (context, ref, _) {
            final ledger = ref.watch(ledgerProvider).take(5).toList();
            return AppCard(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 4),
              child: Column(
                children: [
                  for (int i = 0; i < ledger.length; i++)
                    AppListRow(
                      icon: _ledgerIcon(ledger[i].category),
                      title: ledger[i].title,
                      subtitle: ledger[i].subtitle,
                      showDivider: i != ledger.length - 1,
                      trailing: Text(
                        '${ledger[i].isCredit ? '+' : ''}${ledger[i].amount.toStringAsFixed(2)} ${ledger[i].currency}',
                        style: AppText.tabular.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: ledger[i].isCredit
                              ? AppColors.gain
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SectionTitle('Services'),
        GridView(
          padding: const EdgeInsets.only(bottom: 6),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 20,
            mainAxisExtent: 78,
          ),
          children: [
            IconActionButton(
                icon: AppIcons.send,
                label: 'Send',
                size: 46,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const SendRecipientScreen()))),
            IconActionButton(
                icon: AppIcons.receive,
                label: 'Receive',
                size: 46,
                onTap: () => _openBook('receive')),
            IconActionButton(
                icon: AppIcons.phone,
                label: 'Airtime',
                size: 46,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const AirtimeScreen()))),
            IconActionButton(
                icon: AppIcons.wifi,
                label: 'Data',
                size: 46,
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DataScreen()))),
            IconActionButton(
                icon: AppIcons.bill,
                label: 'Bills',
                size: 46,
                onTap: () => _openBook('bills')),
            IconActionButton(
                icon: AppIcons.target,
                label: 'Savings',
                size: 46,
                onTap: () => _openBook('savings')),
            IconActionButton(
                icon: AppIcons.shield,
                label: 'Escrow',
                size: 46,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const EscrowListScreen()))),
            IconActionButton(
                icon: AppIcons.bag,
                label: 'Merchants',
                size: 46,
                onTap: () => _openBook('merchants')),
            IconActionButton(
                icon: AppIcons.globe,
                label: 'Currency',
                size: 46,
                onTap: () => _openBook('multicurrency')),
            IconActionButton(
                icon: AppIcons.trophy,
                label: 'Rewards',
                size: 46,
                onTap: () => _openBook('rewards')),
          ],
        ),
        const SectionTitle('Announcements'),
        SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _AnnouncementCard(
                title: 'Zero fees on USDT swaps',
                subtitle: 'This week only',
                filled: true,
              ),
              SizedBox(width: 9),
              _AnnouncementCard(
                title: 'Invite friends, earn ₦5,000',
                subtitle: 'Share your referral code',
              ),
              SizedBox(width: 9),
              _AnnouncementCard(
                title: 'Lock savings, earn 14% APY',
                subtitle: 'On stablecoin savings',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.onBell, required this.onProfile});

  final VoidCallback onBell;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final photo = profile.photoFile;
    final initials = profile.displayName.isNotEmpty
        ? (profile.displayName.length >= 2 ? profile.displayName.substring(0, 2).toUpperCase() : profile.displayName.toUpperCase())
        : 'SC';

    return Padding(
      padding: const EdgeInsets.only(bottom: 18, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onProfile,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: photo != null ? null : AppColors.surface2,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderStrong, width: 1.5),
                    image: photo != null
                        ? DecorationImage(image: FileImage(photo), fit: BoxFit.cover)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: photo == null
                      ? Text(
                          initials,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 11),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${profile.displayName}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '@${profile.username} · Lagos, NG',
                      style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconCircleButton(icon: AppIcons.bell, badge: true, onTap: onBell),
              const SizedBox(width: 8),
              IconCircleButton(icon: AppIcons.user, onTap: onProfile),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({required this.label, required this.value, required this.up});

  final String label;
  final String value;
  final bool up;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withOpacity(0.025),
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: up ? AppColors.gain : AppColors.loss)),
        ],
      ),
    );
  }
}

IconData _ledgerIcon(LedgerCategory category) {
  switch (category) {
    case LedgerCategory.transfer:
      return AppIcons.send;
    case LedgerCategory.crypto:
      return AppIcons.coins;
    case LedgerCategory.bill:
      return AppIcons.bill;
    case LedgerCategory.escrow:
      return AppIcons.shield;
    case LedgerCategory.savings:
      return AppIcons.target;
    case LedgerCategory.smartPay:
      return AppIcons.bolt;
    case LedgerCategory.automation:
      return AppIcons.gear;
    case LedgerCategory.fee:
      return AppIcons.receipt;
    case LedgerCategory.refund:
      return AppIcons.repeat;
  }
}

/// A currency the wealth hero card can be viewed in. `flag` is null for
/// the "Crypto" pseudo-currency, which renders a coin glyph instead.
class _CurrencyOption {
  const _CurrencyOption(
      {required this.code,
      required this.symbol,
      required this.amount,
      required this.equivalent,
      this.flag});

  final String code;
  final String symbol;
  final String amount;
  final String equivalent;
  final CountryFlag? flag;
}

const _currencyOptions = [
  _CurrencyOption(
      code: 'NGN',
      symbol: '₦',
      amount: '18,420,650.32',
      equivalent: '≈ \$11,930.00 USD',
      flag: CountryFlag.ng),
  _CurrencyOption(
      code: 'USD',
      symbol: '\$',
      amount: '11,930.00',
      equivalent: '≈ ₦18,420,650.32 NGN',
      flag: CountryFlag.us),
  _CurrencyOption(
      code: 'GHS',
      symbol: '₵',
      amount: '146,320.00',
      equivalent: '≈ \$9,440.00 USD',
      flag: CountryFlag.gh),
  _CurrencyOption(
      code: 'EUR',
      symbol: '€',
      amount: '10,980.40',
      equivalent: '≈ \$11,930.00 USD',
      flag: CountryFlag.eu),
  _CurrencyOption(
      code: 'GBP',
      symbol: '£',
      amount: '9,410.10',
      equivalent: '≈ \$11,930.00 USD',
      flag: CountryFlag.gb),
  _CurrencyOption(
      code: 'Crypto',
      symbol: '\$',
      amount: '8,940.20',
      equivalent: 'Combined crypto holdings'),
];

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow(
      {required this.option,
      required this.selected,
      required this.onTap,
      this.showDivider = true});

  final _CurrencyOption option;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: AppColors.hairline))
              : null,
        ),
        child: Row(
          children: [
            if (option.flag != null)
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.hairline),
                    borderRadius: BorderRadius.circular(11)),
                child: FlagChip(flag: option.flag!),
              )
            else
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: AppColors.accentSoft, shape: BoxShape.circle),
                child: Icon(AppIcons.coins,
                    size: 15, color: AppColors.accent),
              ),
            const SizedBox(width: 12),
            Expanded(child: Text(option.code, style: AppText.body)),
            if (selected)
              Icon(AppIcons.check, size: 18, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

/// Announcement card — same ring-circle motif as the wealth hero card
/// and the auth backdrop, scaled down, so promo cards read as the same
/// product instead of plain flat rectangles.
class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.title,
    required this.subtitle,
    this.filled = false,
  });

  final String title;
  final String subtitle;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: 92,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: filled ? AppColors.accentGradient : AppColors.heroGradient,
        border: filled ? null : Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -34,
            right: -26,
            child: RingCircle(
                size: 100,
                color: (filled ? Colors.white : AppColors.accent)
                    .withOpacity(filled ? 0.18 : 0.35),
                width: 14),
          ),
          Positioned(
            bottom: -38,
            left: -22,
            child: RingCircle(
                size: 76,
                color: (filled ? Colors.white : AppColors.accent)
                    .withOpacity(filled ? 0.10 : 0.16),
                width: 12),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: filled ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: filled ? Colors.white70 : AppColors.textSecondary,
                      fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textPrimary),
          const SizedBox(width: 7),
          Text(title, style: AppText.cardTitle),
        ],
      ),
    );
  }
}

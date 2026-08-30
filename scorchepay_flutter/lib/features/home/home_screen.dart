import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/charts/wealth_line_chart.dart';
import '../../core/widgets/list_row.dart';
import '../../core/widgets/section_title.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../crypto/crypto_screen.dart';
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

  void _openBook(String id) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: id)));
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
                      Container(
                        padding: const EdgeInsets.fromLTRB(8, 4, 9, 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          border: Border.all(color: AppColors.borderStrong),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('NGN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                            Icon(AppIcons.chevronDown, size: 13, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _hideBalance = !_hideBalance),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(_hideBalance ? AppIcons.eyeOff : AppIcons.eye, size: 17, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: _hideBalance ? 8 : 0, sigmaY: _hideBalance ? 8 : 0),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '₦', style: AppText.heroNumberMedium.copyWith(color: AppColors.textSecondary, fontSize: 24)),
                      const TextSpan(text: '18,420,650.32', style: AppText.heroNumber),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 3),
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: _hideBalance ? 8 : 0, sigmaY: _hideBalance ? 8 : 0),
                child: const Text('≈ \$11,930.00 USD', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
              ),
              const SizedBox(height: 11),
              const Row(
                children: [
                  Icon(AppIcons.arrowUpRight, size: 13, color: AppColors.gain),
                  SizedBox(width: 5),
                  Text('+2.4% today', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.gain)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(child: _StatMini(label: 'Today', value: '+2.4%', up: true)),
                  SizedBox(width: 8),
                  Expanded(child: _StatMini(label: 'This week', value: '+6.1%', up: true)),
                  SizedBox(width: 8),
                  Expanded(child: _StatMini(label: 'This month', value: '−1.8%', up: false)),
                ],
              ),
              const SizedBox(height: 16),
              WealthLineChart(points: MockData.wealthTrend),
              const SizedBox(height: 2),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('6d ago', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.muted)),
                  Text('4d', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.muted)),
                  Text('2d', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.muted)),
                  Text('Today', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.muted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: AppIcons.bolt,
                label: 'Smart Pay',
                primary: true,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SmartPayScreen())),
              ),
            ),
            Expanded(
              child: _QuickAction(icon: AppIcons.send, label: 'Send', onTap: () => _openBook('send')),
            ),
            Expanded(
              child: _QuickAction(icon: AppIcons.receive, label: 'Receive', onTap: () => _openBook('receive')),
            ),
            Expanded(
              child: _QuickAction(
                icon: AppIcons.coins,
                label: 'Crypto',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CryptoScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
          child: Column(
            children: [
              const _CardHeader(icon: AppIcons.bell, title: 'Needs your attention'),
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
                onTap: () => _openBook('escrow'),
              ),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
          child: Column(
            children: [
              const _CardHeader(icon: AppIcons.sparkle, title: 'Smart insights'),
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
        SectionTitle('Recent activity', action: 'See all', onAction: () => _openBook('transactions')),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 4),
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
                      fontSize: 13,
                      color: MockData.activity[i].isCredit ? AppColors.gain : AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SectionTitle('Services'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 6,
            childAspectRatio: 0.82,
            children: [
              _ServiceItem(icon: AppIcons.send, label: 'Send', onTap: () => _openBook('send')),
              _ServiceItem(icon: AppIcons.receive, label: 'Receive', onTap: () => _openBook('receive')),
              _ServiceItem(icon: AppIcons.bill, label: 'Bills', onTap: () => _openBook('bills')),
              _ServiceItem(icon: AppIcons.target, label: 'Savings', onTap: () => _openBook('savings')),
              _ServiceItem(icon: AppIcons.shield, label: 'Escrow', onTap: () => _openBook('escrow')),
              _ServiceItem(icon: AppIcons.bag, label: 'Merchants', onTap: () => _openBook('merchants')),
              _ServiceItem(icon: AppIcons.globe, label: 'Currency', onTap: () => _openBook('multicurrency')),
              _ServiceItem(icon: AppIcons.trophy, label: 'Rewards', onTap: () => _openBook('rewards')),
            ],
          ),
        ),
        const SectionTitle('Announcements'),
        SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Container(
                width: 230,
                height: 92,
                margin: const EdgeInsets.only(right: 9),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(gradient: AppColors.accentGradient, borderRadius: BorderRadius.circular(18)),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Zero fees on USDT swaps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    SizedBox(height: 4),
                    Text('This week only', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                width: 230,
                height: 92,
                margin: const EdgeInsets.only(right: 9),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invite friends, earn ₦5,000', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    SizedBox(height: 4),
                    Text('Share your referral code', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                width: 230,
                height: 92,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lock savings, earn 14% APY', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    SizedBox(height: 4),
                    Text('On stablecoin savings', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBell, required this.onProfile});

  final VoidCallback onBell;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderStrong),
                ),
                alignment: Alignment.center,
                child: const Text('SC', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 11),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good evening, Scorche', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.textPrimary)),
                  SizedBox(height: 1),
                  Text('@scorche · Lagos, NG', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                ],
              ),
            ],
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
        color: Colors.white.withOpacity(0.025),
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: up ? AppColors.gain : AppColors.loss)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap, this.primary = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: primary ? AppColors.accentGradient : null,
                color: primary ? null : AppColors.surface,
                border: primary ? null : Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.md + 2),
                boxShadow: primary
                    ? [BoxShadow(color: AppColors.accent.withOpacity(0.45), blurRadius: 16, offset: const Offset(0, 6))]
                    : null,
              ),
              child: Icon(icon, size: 21, color: primary ? Colors.white : AppColors.textSecondary),
            ),
            const SizedBox(height: 7),
            Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  const _ServiceItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
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

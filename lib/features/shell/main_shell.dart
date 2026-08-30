import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_icons.dart';
import '../../state/providers/providers.dart';
import '../../theme/app_colors.dart';
import '../crypto/crypto_screen.dart';
import '../home/home_screen.dart';
import '../more/more_hub_screen.dart';
import '../send/quick_pay_screen.dart';
import '../wallet/wallet_screen.dart';

/// Root scaffold once the user is signed in: floating bottom tab bar
/// (Home, Wallet, QR FAB, Crypto, More) driving an [IndexedStack] so tab
/// state is preserved across switches. No active-tab dot indicator —
/// the icon sitting inside a soft accent chip is signal enough.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;
  Timer? _timer;

  static const _screens = [
    HomeScreen(),
    WalletScreen(),
    CryptoScreen(),
    MoreHubScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // No real backend cron in this prototype — this is what makes
    // escrow review-window auto-release and due automation rules
    // actually resolve while the user is sitting in the app, instead of
    // only reacting to manual taps (spec §10 / §23).
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      final notifier = ref.read(appStateProvider.notifier);
      notifier.checkExpiredReviewWindows();
      notifier.runDueRules();
      // FxRateService caches for 1h internally, so this is a cheap no-op
      // on most ticks — it just means rates go stale for at most an
      // hour instead of only refreshing on cold start.
      notifier.refreshFxRates();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Center QR action: show-my-code / scan-to-pay / jump straight into
  // Send or Receive. Smart Pay itself stays reachable from the Home
  // quick-actions row, so this FAB is free to be a QR-first shortcut.
  void _openQuickPay() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const QuickPayScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
        onQr: _openQuickPay,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar(
      {required this.index, required this.onTap, required this.onQr});

  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onQr;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding:
          EdgeInsets.fromLTRB(14, 0, 14, safeBottom > 0 ? safeBottom - 4 : 12),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xF0121214),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.hairline),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _NavItem(
                icon: AppIcons.home,
                label: 'Home',
                selected: index == 0,
                onTap: () => onTap(0)),
            _NavItem(
                icon: AppIcons.wallet,
                label: 'Wallet',
                selected: index == 1,
                onTap: () => onTap(1)),
            _QrFab(onTap: onQr),
            _NavItem(
                icon: AppIcons.coins,
                label: 'Crypto',
                selected: index == 2,
                onTap: () => onTap(2)),
            _NavItem(
                icon: AppIcons.grid,
                label: 'More',
                selected: index == 3,
                onTap: () => onTap(3)),
          ],
        ),
      ),
    );
  }
}

/// Minimal nav item: no background shape and no active-state dot — just
/// icon/label color shifting to the accent, the flattest possible tab
/// bar treatment.
class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.muted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 9.5, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _QrFab extends StatelessWidget {
  const _QrFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -26),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.accentGradient,
            border: Border.all(color: AppColors.page, width: 4),
            boxShadow: [
              BoxShadow(
                  color: AppColors.accent.withOpacity(0.55),
                  blurRadius: 22,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: const Icon(AppIcons.qr, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

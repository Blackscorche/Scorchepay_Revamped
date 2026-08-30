import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import '../../theme/app_colors.dart';
import '../crypto/crypto_screen.dart';
import '../home/home_screen.dart';
import '../more/more_hub_screen.dart';
import '../smart_pay/smart_pay_screen.dart';
import '../wallet/wallet_screen.dart';

/// Root scaffold once the user is signed in: bottom tab bar (Home,
/// Wallet, Smart Pay FAB, Crypto, More) driving an [IndexedStack] so tab
/// state is preserved across switches. No active-tab dot indicator —
/// icon/label going from muted to full-white text is signal enough.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    WalletScreen(),
    CryptoScreen(),
    MoreHubScreen(),
  ];

  // Smart Pay is reachable both from the center FAB and pushed as a
  // full route so it can be popped back to whichever tab was active.
  void _openSmartPay() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SmartPayScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
        onPay: _openSmartPay,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onTap, required this.onPay});

  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(top: 10, bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.page.withOpacity(0.92),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NavItem(icon: AppIcons.home, label: 'Home', selected: index == 0, onTap: () => onTap(0)),
          _NavItem(icon: AppIcons.wallet, label: 'Wallet', selected: index == 1, onTap: () => onTap(1)),
          _PayFab(onTap: onPay),
          _NavItem(icon: AppIcons.coins, label: 'Crypto', selected: index == 2, onTap: () => onTap(2)),
          _NavItem(icon: AppIcons.grid, label: 'More', selected: index == 3, onTap: () => onTap(3)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.muted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _PayFab extends StatelessWidget {
  const _PayFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -22),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.accentGradient,
            border: Border.all(color: AppColors.page, width: 4),
            boxShadow: [
              BoxShadow(color: AppColors.accent.withOpacity(0.55), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: const Icon(AppIcons.bolt, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

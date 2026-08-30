import 'package:flutter/material.dart';
import '../core/app_icons.dart';
import '../core/widgets/flag_chip.dart';
import '../theme/app_colors.dart';
import 'models.dart';

/// All placeholder content for the prototype in one place, mirroring the
/// data used in the original HTML mockup so the two stay in sync.
class MockData {
  MockData._();

  static const List<BookItem> books = [
    BookItem(
        id: 'send',
        group: 'Pay & Move',
        icon: AppIcons.send,
        title: 'Send Money',
        blurb: 'Username · QR · Bank · Wallet address',
        type: BookType.send),
    BookItem(
        id: 'receive',
        group: 'Pay & Move',
        icon: AppIcons.receive,
        title: 'Receive Money',
        blurb: 'One QR for bank, wallet & crypto',
        type: BookType.receive),
    BookItem(
        id: 'bills',
        group: 'Pay & Move',
        icon: AppIcons.bill,
        title: 'Bills',
        blurb: 'Airtime, data, electricity & more',
        type: BookType.bills),
    BookItem(
        id: 'escrow',
        group: 'Pay & Move',
        icon: AppIcons.shield,
        title: 'Escrow',
        blurb: 'Any payment can become an escrow',
        type: BookType.escrow),
    BookItem(
        id: 'merchants',
        group: 'Pay & Move',
        icon: AppIcons.bag,
        title: 'Merchants',
        blurb: 'Accept payments, invoices, settlements',
        type: BookType.merchant),
    BookItem(
        id: 'crossborder',
        group: 'Pay & Move',
        icon: AppIcons.globe,
        title: 'Cross-Border',
        blurb: 'Send & receive across currencies',
        type: BookType.crossBorder),
    BookItem(
        id: 'automation',
        group: 'Pay & Move',
        icon: AppIcons.gear,
        title: 'Automation',
        blurb: 'Rules engine for auto-pay & auto-save',
        type: BookType.automation),
    BookItem(
        id: 'multicurrency',
        group: 'Money',
        icon: AppIcons.globe,
        title: 'Multi-Currency',
        blurb: 'NGN · GHS · USD · EUR · GBP + more',
        type: BookType.multiCurrency),
    BookItem(
        id: 'savings',
        group: 'Money',
        icon: AppIcons.target,
        title: 'Savings',
        blurb: 'Goals, lock, round-up & group savings',
        type: BookType.savings),
    BookItem(
        id: 'group',
        group: 'Money',
        icon: AppIcons.users,
        title: 'Group Features',
        blurb: 'Group savings & shared contributions',
        type: BookType.group),
    BookItem(
        id: 'transactions',
        group: 'Money',
        icon: AppIcons.receipt,
        title: 'Transactions',
        blurb: 'History, filters, receipts, export',
        type: BookType.transactions),
    BookItem(
        id: 'insights',
        group: 'Grow & Insights',
        icon: AppIcons.chartLine,
        title: 'Insights',
        blurb: 'Cash flow, budgets & financial health',
        type: BookType.insights),
    BookItem(
        id: 'analytics',
        group: 'Grow & Insights',
        icon: AppIcons.chartBar,
        title: 'Analytics',
        blurb: 'Spending, income, crypto & merchant data',
        type: BookType.analytics),
    BookItem(
        id: 'ai',
        group: 'Grow & Insights',
        icon: AppIcons.sparkle,
        title: 'AI Assistant',
        blurb: 'Smart insights & financial coaching',
        type: BookType.ai),
    BookItem(
        id: 'rewards',
        group: 'Grow & Insights',
        icon: AppIcons.trophy,
        title: 'Rewards',
        blurb: 'Referrals, cashback & loyalty tiers',
        type: BookType.rewards),
    BookItem(
        id: 'profile',
        group: 'Account',
        icon: AppIcons.user,
        title: 'Profile',
        blurb: 'Username, KYC, preferences',
        type: BookType.profile),
    BookItem(
        id: 'security',
        group: 'Account',
        icon: AppIcons.lock,
        title: 'Security',
        blurb: 'PIN, biometrics, 2FA & device controls',
        type: BookType.security),
    BookItem(
        id: 'notifications',
        group: 'Account',
        icon: AppIcons.bell,
        title: 'Notifications',
        blurb: 'All your alerts in one feed',
        type: BookType.notifications),
    BookItem(
        id: 'business',
        group: 'Business & Dev',
        icon: AppIcons.briefcase,
        title: 'Business Tools',
        blurb: 'Invoices, payment pages, verification',
        type: BookType.business),
    BookItem(
        id: 'developer',
        group: 'Business & Dev',
        icon: AppIcons.code,
        title: 'Developer Platform',
        blurb: 'API keys, webhooks, sandbox, SDKs',
        type: BookType.developer),
  ];

  static const List<CryptoAsset> crypto = [
    CryptoAsset(
        symbol: 'BTC',
        name: 'Bitcoin',
        glyph: '₿',
        price: 96240,
        changePct: 2.1,
        holding: '0.0842',
        color: Color(0xFFF7931A)),
    CryptoAsset(
        symbol: 'ETH',
        name: 'Ethereum',
        glyph: 'Ξ',
        price: 4120,
        changePct: -1.3,
        holding: '1.42',
        color: Color(0xFF8C9EFF)),
    CryptoAsset(
        symbol: 'USDT',
        name: 'Tether',
        glyph: '₮',
        price: 1.00,
        changePct: 0.0,
        holding: '1,850',
        color: Color(0xFF20C9A6)),
    CryptoAsset(
        symbol: 'SOL',
        name: 'Solana',
        glyph: '◎',
        price: 238,
        changePct: 5.8,
        holding: '9.6',
        color: Color(0xFFC299FF)),
    CryptoAsset(
        symbol: 'BNB',
        name: 'BNB',
        glyph: 'B',
        price: 712,
        changePct: 0.4,
        holding: '1.1',
        color: Color(0xFFF0B90B)),
  ];

  static const List<FiatBalance> balances = [
    FiatBalance(code: 'NGN', flag: CountryFlag.ng, amount: '₦6,264,000.00'),
    FiatBalance(code: 'USD', flag: CountryFlag.us, amount: '\$3,120.40'),
    FiatBalance(code: 'GHS', flag: CountryFlag.gh, amount: '₵1,850.00'),
    FiatBalance(code: 'EUR', flag: CountryFlag.eu, amount: '€640.00'),
    FiatBalance(code: 'GBP', flag: CountryFlag.gb, amount: '£210.00'),
    FiatBalance(code: 'INR', flag: CountryFlag.inr, amount: '₹42,180.00'),
    FiatBalance(code: 'CNY', flag: CountryFlag.cny, amount: '¥8,240.00'),
    FiatBalance(code: 'SAR', flag: CountryFlag.sar, amount: 'SAR 1,960.00'),
    FiatBalance(code: 'AED', flag: CountryFlag.aed, amount: 'AED 2,410.00'),
  ];

  static const List<AllocationSlice> allocation = [
    AllocationSlice(label: 'NGN', pct: 34, color: AppColors.accent),
    AllocationSlice(label: 'Crypto', pct: 28, color: AppColors.accentTint1),
    AllocationSlice(label: 'USD', pct: 20, color: AppColors.accentShade1),
    AllocationSlice(label: 'GHS', pct: 11, color: AppColors.accentTint2),
    AllocationSlice(label: 'EUR / GBP', pct: 7, color: AppColors.accentShade2),
  ];

  static const List<ActivityItem> activity = [
    ActivityItem(
        icon: AppIcons.receive,
        title: 'Received from @ada_b',
        subtitle: 'Today · 10:24 AM',
        amount: '+ ₦85,000',
        isCredit: true,
        category: ActivityCategory.money),
    ActivityItem(
        icon: AppIcons.bolt,
        title: 'Smart Pay · MTN Data',
        subtitle: 'Today · 8:02 AM',
        amount: '− ₦3,500',
        isCredit: false,
        category: ActivityCategory.bills),
    ActivityItem(
        icon: AppIcons.coins,
        title: 'Bought 0.004 BTC',
        subtitle: 'Yesterday · 6:40 PM',
        amount: '− \$150.00',
        isCredit: false,
        category: ActivityCategory.crypto),
    ActivityItem(
        icon: AppIcons.shield,
        title: 'Escrow released · Freelance',
        subtitle: 'Yesterday · 2:15 PM',
        amount: '+ \$420.00',
        isCredit: true,
        category: ActivityCategory.escrow),
    ActivityItem(
        icon: AppIcons.target,
        title: 'Auto-save · Rent Goal',
        subtitle: 'Mon · 12:00 AM',
        amount: '− ₦10,000',
        isCredit: false,
        category: ActivityCategory.money),
  ];

  static const List<SavingsGoal> savingsGoals = [
    SavingsGoal(
        icon: AppIcons.building,
        name: 'New Car',
        tag: 'On track',
        tagColor: AppColors.gain,
        progress: 0.68,
        saved: '₦3.4M',
        target: '₦5M'),
    SavingsGoal(
        icon: AppIcons.building,
        name: 'Rent (Locked)',
        tag: 'Locked',
        tagColor: AppColors.info,
        progress: 0.90,
        saved: '₦1.8M',
        target: '₦2M'),
    SavingsGoal(
        icon: AppIcons.shield,
        name: 'Emergency Fund',
        tag: 'Auto-save',
        progress: 0.40,
        saved: '\$400',
        target: '\$1,000'),
    SavingsGoal(
        icon: AppIcons.coins,
        name: 'Stablecoin Savings',
        tag: '14% APY',
        tagColor: AppColors.gain,
        progress: 0.25,
        saved: '\$250 USDT',
        target: '\$1,000 USDT'),
  ];

  static const List<double> wealthTrend = [
    40.0,
    55,
    50,
    70,
    64,
    80,
    72,
    90,
    84,
    100,
    96,
    112
  ];

  // A choppier, more volatile shape than wealthTrend — crypto reads as
  // its own asset class rather than reusing the fiat balance's curve.
  static const List<double> cryptoTrend = [
    58.0,
    64,
    52,
    60,
    78,
    70,
    88,
    76,
    94,
    82,
    100,
    92
  ];

  static BookItem? bookById(String id) {
    for (final b in books) {
      if (b.id == id) return b;
    }
    return null;
  }
}

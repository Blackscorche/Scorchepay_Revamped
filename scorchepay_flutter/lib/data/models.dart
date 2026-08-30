import 'package:flutter/material.dart';
import '../core/widgets/flag_chip.dart';

/// The 20 "books" from the ScorchePay product roadmap, used to drive the
/// More hub grid and the generic [BookDetailScreen]. Keeping this
/// data-driven (rather than one bespoke screen per book) is what let the
/// original HTML prototype cover the full roadmap without 20 hand-built
/// screens — the Flutter app mirrors that approach.
enum BookType {
  send, receive, bills, escrow, merchant, crossBorder, automation,
  simpleList, savings, group, transactions, insights, ai, rewards,
  profile, security, notifications, business, developer,
}

class BookItem {
  const BookItem({
    required this.id,
    required this.group,
    required this.icon,
    required this.title,
    required this.blurb,
    required this.type,
    this.features = const [],
  });

  final String id;
  final String group;
  final IconData icon;
  final String title;
  final String blurb;
  final BookType type;
  final List<String> features;
}

class CryptoAsset {
  const CryptoAsset({
    required this.symbol,
    required this.name,
    required this.glyph,
    required this.price,
    required this.changePct,
    required this.holding,
    required this.color,
  });

  final String symbol;
  final String name;
  final String glyph;
  final double price;
  final double changePct;
  final String holding;
  final Color color;
}

class FiatBalance {
  const FiatBalance({required this.code, required this.flag, required this.amount});
  final String code;
  final CountryFlag flag;
  final String amount;
}

class AllocationSlice {
  const AllocationSlice({required this.label, required this.pct, required this.color});
  final String label;
  final double pct;
  final Color color;
}

class ActivityItem {
  const ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final bool isCredit;
}

class SavingsGoal {
  const SavingsGoal({
    required this.icon,
    required this.name,
    required this.tag,
    required this.progress,
    required this.saved,
    required this.target,
    this.tagColor,
  });

  final IconData icon;
  final String name;
  final String tag;
  final double progress;
  final String saved;
  final String target;
  final Color? tagColor;
}

import 'package:flutter/material.dart';
import '../../core/widgets/scorch_mascot.dart';
import 'package:flutter/foundation.dart';
import '../exchange/exchange_workspace_screen.dart';

import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/icon_action_button.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../flows/escrow/escrow_list_screen.dart';
import '../flows/send/send_recipient_screen.dart';
import 'appearance_screen.dart';
import 'book_detail_screen.dart';

/// More hub — every feature from the product roadmap with live search filter.
class MoreHubScreen extends StatefulWidget {
  const MoreHubScreen({super.key});

  @override
  State<MoreHubScreen> createState() => _MoreHubScreenState();
}

class _MoreHubScreenState extends State<MoreHubScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static Widget _openBook(String id) {
    switch (id) {
      case 'gift_exchange':
        return const ExchangeWorkspaceScreen(
            workspace: ExchangeWorkspace.giftCards);
      case 'p2p_market':
        return const ExchangeWorkspaceScreen(workspace: ExchangeWorkspace.p2p);
      case 'merchant_exchange':
        return const ExchangeWorkspaceScreen(
            workspace: ExchangeWorkspace.merchant);
      case 'admin_exchange':
        return const ExchangeWorkspaceScreen(
            workspace: ExchangeWorkspace.admin);
      case 'send':
        return const SendRecipientScreen();
      case 'escrow':
        return const EscrowListScreen();
      case 'appearance':
        return const AppearanceScreen();
      default:
        return BookDetailScreen(bookId: id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allBooks = MockData.books
        .where((book) =>
            kDebugMode ||
            !{'merchant_exchange', 'admin_exchange'}.contains(book.id))
        .toList();
    final filtered = _searchQuery.isEmpty
        ? allBooks
        : allBooks.where((b) {
            final q = _searchQuery.toLowerCase();
            return b.title.toLowerCase().contains(q) ||
                b.blurb.toLowerCase().contains(q) ||
                b.group.toLowerCase().contains(q);
          }).toList();

    final groups = <String>[];
    for (final b in filtered) {
      if (!groups.contains(b.group)) groups.add(b.group);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
      children: [
        const SizedBox(height: 4),
        Text('More', style: AppText.pageTitle),
        const ScorchCompanion(activity: ScorchActivity.explore, title: 'Find your next move', message: 'Savings, payments and everyday tools, all together.'),

        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v.trim()),
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'Search ScorchePay features...',
            prefixIcon: Icon(AppIcons.search, size: 18, color: AppColors.muted),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child:
                        Icon(AppIcons.trash, size: 16, color: AppColors.muted),
                  )
                : null,
          ),
        ),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(AppIcons.search, size: 36, color: AppColors.muted),
                  const SizedBox(height: 12),
                  Text('No features found for "$_searchQuery"',
                      style: AppText.bodyMuted),
                ],
              ),
            ),
          )
        else
          for (final group in groups) ...[
            Padding(
              padding:
                  const EdgeInsets.only(top: 14, bottom: 22, left: 2, right: 2),
              child: Text(
                group.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    letterSpacing: 0.7),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                const cols = 4;
                const hGap = 4.0;
                final itemWidth =
                    (constraints.maxWidth - hGap * (cols - 1)) / cols;
                return Wrap(
                  spacing: hGap,
                  runSpacing: 14,
                  children: [
                    for (final book in filtered.where((b) => b.group == group))
                      SizedBox(
                        width: itemWidth,
                        child: IconActionButton(
                          icon: book.icon,
                          label: book.title,
                          size: 48,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => _openBook(book.id))),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        AppCard(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          color: AppColors.accentSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(AppIcons.flame, size: 16, color: AppColors.accent),
                  SizedBox(width: 7),
                  Text('The Money OS philosophy', style: AppText.cardTitle),
                ],
              ),
              SizedBox(height: 8),
              Text(
                "Users don't manage banks, wallets, or crypto. Users manage their money — ScorchePay handles the rest, invisibly.",
                style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

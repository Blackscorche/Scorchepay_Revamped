import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'book_detail_screen.dart';

/// More hub — every "book" from the product roadmap, grouped exactly as
/// they first appear in [MockData.books]. Mirrors renderMore() in the
/// HTML prototype.
class MoreHubScreen extends StatelessWidget {
  const MoreHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = <String>[];
    for (final b in MockData.books) {
      if (!groups.contains(b.group)) groups.add(b.group);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
      children: [
        const SizedBox(height: 4),
        const Text('More', style: AppText.pageTitle),
        const SizedBox(height: 16),
        TextField(
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'Search ScorchePay',
            prefixIcon: const Icon(AppIcons.search, size: 18, color: AppColors.muted),
          ),
        ),
        for (final group in groups) ...[
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10, left: 2, right: 2),
            child: Text(
              group.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.7),
            ),
          ),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 6,
            childAspectRatio: 0.72,
            children: [
              for (final book in MockData.books.where((b) => b.group == group)) _HubItem(book: book),
            ],
          ),
        ],
        AppCard(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          color: AppColors.accentSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(AppIcons.flame, size: 16, color: AppColors.accent),
                  SizedBox(width: 7),
                  Text('The Money OS philosophy', style: AppText.cardTitle),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Users don't manage banks, wallets, or crypto. Users manage their money — ScorchePay handles the rest, invisibly.",
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HubItem extends StatelessWidget {
  const _HubItem({required this.book});

  final BookItem book;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id))),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(book.icon, size: 19, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 7),
          Text(
            book.title,
            style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600, height: 1.25),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

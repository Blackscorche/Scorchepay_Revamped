import 'package:flutter/material.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/list_row.dart';
import '../../../state/models/demo_account.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'send_confirm_recipient_screen.dart';

/// Step 1 of Send Money — pick or search a recipient. Tapping one
/// resolves against [DemoAccounts] and pushes the anti-mis-send confirm
/// step; typing a username that doesn't match shows an inline
/// "no user found" state rather than silently doing nothing.
class SendRecipientScreen extends StatefulWidget {
  const SendRecipientScreen({super.key});

  @override
  State<SendRecipientScreen> createState() => _SendRecipientScreenState();
}

class _SendRecipientScreenState extends State<SendRecipientScreen> {
  final _controller = TextEditingController();
  bool _notFound = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pick(DemoAccount account) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SendConfirmRecipientScreen(account: account)));
  }

  void _searchSubmit() {
    final match = DemoAccounts.byUsername(_controller.text.trim());
    if (match == null) {
      setState(() => _notFound = true);
      return;
    }
    _pick(match);
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final results = query.isEmpty
        ? DemoAccounts.all
        : DemoAccounts.all
            .where((a) =>
                a.username.toLowerCase().contains(query) ||
                a.displayName.toLowerCase().contains(query))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(AppIcons.chevronLeft,
                          color: AppColors.textPrimary)),
                  const SizedBox(width: 4),
                  const Text('Send Money', style: AppText.pageTitle),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                onChanged: (_) => setState(() => _notFound = false),
                onSubmitted: (_) => _searchSubmit(),
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13.5),
                decoration: const InputDecoration(
                  hintText: '@username or search contacts',
                  prefixIcon:
                      Icon(AppIcons.user, size: 18, color: AppColors.muted),
                ),
              ),
              if (_notFound) ...[
                const SizedBox(height: 10),
                const Text('No user found with that username.',
                    style: TextStyle(
                        color: AppColors.loss,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 18),
              const Text('CONTACTS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                      letterSpacing: 0.7)),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, i) => AppListRow(
                    icon: AppIcons.user,
                    title: results[i].displayName,
                    subtitle: results[i].username,
                    onTap: () => _pick(results[i]),
                    showDivider: i != results.length - 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

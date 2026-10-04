import 'package:flutter/material.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/detail_header.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Reviewable UI fixtures only. Production workspaces require server roles,
/// durable orders and ledger settlement before transaction actions are enabled.
enum ExchangeWorkspace { giftCards, p2p, merchant, admin }

class ExchangeWorkspaceScreen extends StatefulWidget {
  const ExchangeWorkspaceScreen({super.key, required this.workspace});
  final ExchangeWorkspace workspace;

  @override
  State<ExchangeWorkspaceScreen> createState() =>
      _ExchangeWorkspaceScreenState();
}

class _ExchangeWorkspaceScreenState extends State<ExchangeWorkspaceScreen> {
  int _tab = 0;
  String _query = '';

  String get _title => switch (widget.workspace) {
        ExchangeWorkspace.giftCards => 'Gift card exchange',
        ExchangeWorkspace.p2p => 'P2P marketplace',
        ExchangeWorkspace.merchant => 'Merchant dashboard',
        ExchangeWorkspace.admin => 'Exchange operations',
      };

  List<String> get _tabs => switch (widget.workspace) {
        ExchangeWorkspace.giftCards => ['Sell cards', 'Buy cards', 'My orders'],
        ExchangeWorkspace.p2p => ['Buy crypto', 'Sell crypto', 'My orders'],
        ExchangeWorkspace.merchant => ['Orders', 'Rates', 'Settlements'],
        ExchangeWorkspace.admin => [
            'Review queue',
            'Merchants',
            'Reconciliation'
          ],
      };

  List<_Entry> get _entries => switch (widget.workspace) {
        ExchangeWorkspace.giftCards => switch (_tab) {
            0 => const [
                _Entry('Amazon US', 'Physical / digital · USD', 'Get a quote',
                    'Choose the card region, format and value. A server quote will show the payout currency, fees, expiry and expected review time before submission.'),
                _Entry('Apple US', 'Digital · USD', 'Get a quote',
                    'Upload card evidence privately after accepting a quote. Card codes are only revealed to the assigned reviewer; payout follows approval.'),
                _Entry('Steam US', 'Physical / digital · USD', 'Get a quote',
                    'Rates vary by region, denomination and card format. Final payout must be confirmed by a funded merchant offer.'),
              ],
            1 => const [
                _Entry(
                    'Digital gift cards',
                    'Brand · region · denomination',
                    'Planned',
                    'Browse supplier-backed inventory, review regional restrictions, pay with Smart Pay and receive the purchased code securely. Supplier integration is pending.'),
              ],
            _ => const [
                _Entry(
                    'GC-1042 · Amazon US',
                    'Sample order · \$100 digital card',
                    'In review',
                    'Submitted → assigned → in review → offer accepted → settled. This sample has no uploaded card or wallet transaction.'),
                _Entry(
                    'GC-1038 · Steam US',
                    'Sample order · \$50 physical card',
                    'Needs evidence',
                    'The merchant requests a clearer receipt. Production orders will support private evidence, a response deadline and dispute escalation.'),
              ],
          },
        ExchangeWorkspace.p2p => _tab == 2
            ? const [
                _Entry(
                    'P2P-2081 · Buy USDT',
                    'Sample order · 50 USDT',
                    'Awaiting payment',
                    'Crypto must be reserved before payment instructions appear. The buyer marks paid; only confirmed receipt or an audited dispute decision can release escrow.'),
              ]
            : [
                _Entry(
                    'Ada Markets · USDT',
                    'Sample merchant · Bank transfer',
                    _tab == 0 ? 'Buy offer' : 'Sell offer',
                    'Preview offer: ₦20,000–₦500,000 limits. Production offers show executable rates, available inventory, completed trades, payment window and verified payment methods.'),
                _Entry(
                    'Ember Exchange · BTC',
                    'Sample merchant · Bank transfer',
                    _tab == 0 ? 'Buy offer' : 'Sell offer',
                    'Choose an amount within the offer limits. The server validates inventory, identity and settlement method before creating an escrow order. No rate is executable in this preview.'),
              ],
        ExchangeWorkspace.merchant => switch (_tab) {
            0 => const [
                _Entry(
                    'GC-1042 · Amazon US',
                    'Assigned to your team · \$100',
                    'Review card',
                    'Merchant review workspace: securely reveal the assigned card, inspect evidence, approve the agreed payout, propose a revised offer with a reason, or reject with evidence. No approval is sent from this preview.'),
                _Entry(
                    'P2P-2081 · USDT',
                    'Sample order · 50 USDT',
                    'Payment check',
                    'Confirm funds at the actual payment destination. A receipt upload or buyer claim cannot automatically release reserved crypto. Disputed orders remain frozen.'),
              ],
            1 => const [
                _Entry(
                    'Amazon US · Digital',
                    'USD face value → NGN payout',
                    'Draft rate',
                    'Configure denomination bands, spread, minimum/maximum order, capacity and quote validity. Publishing requires an approved merchant and available settlement funds.'),
                _Entry('USDT / NGN', 'Buy and sell advertisements', 'Paused',
                    'Manage price, inventory, limits, bank details, payment window and availability. Pausing stops new orders while existing obligations remain active.'),
              ],
            _ => const [
                _Entry(
                    'Settlement balance',
                    'Available · reserved · pending',
                    'Not connected',
                    'Production balances come from the ledger. Gift card payouts reserve merchant funds and atomically credit the customer when an approved order settles.'),
                _Entry(
                    'Settlement history',
                    'Fees · net proceeds · export',
                    'Sample report',
                    'Filter settled orders by date and currency; inspect payout references and download a statement. External P2P bank receipts are separate from ScorchePay wallet credits.'),
              ],
          },
        ExchangeWorkspace.admin => switch (_tab) {
            0 => const [
                _Entry(
                    'GC-1038 · Evidence dispute',
                    'Gift cards · sample case',
                    'Needs review',
                    'Inspect both parties’ evidence and the immutable order timeline. Record a reason and request independent approval for a financial adjustment. Never edit a wallet balance directly.'),
                _Entry(
                    'P2P-2075 · Payment disputed',
                    'P2P · sample case',
                    'Escrow held',
                    'Freeze release while the case is open. Review verified payment details, communications and deadlines before an authorized release or refund.'),
              ],
            1 => const [
                _Entry(
                    'Ember Exchange',
                    'Sample business application',
                    'KYB review',
                    'Review business identity, owners, settlement accounts, supported regions and risk limits. Approve, request information or suspend with an audited reason.'),
                _Entry(
                    'Merchant permissions',
                    'Operators · reviewers · owners',
                    'Role policy',
                    'Every server request is scoped to merchant membership and permission. Admin access uses a separate protected workspace with MFA; hiding a menu is not access control.'),
              ],
            _ => const [
                _Entry(
                    'Provider reconciliation',
                    'Ledger ↔ provider statements',
                    'Not connected',
                    'Compare collections, conversions and payouts by currency and reference. Route unmatched transactions to investigation without automatically refunding unknown outcomes.'),
                _Entry(
                    'Provider health',
                    'SMEPlug · Paystack · FX · Crypto',
                    'Not connected',
                    'Monitor balances, pending jobs, failed webhooks and settlement delays. Replay verified events idempotently; pause affected products when liquidity or providers are unavailable.'),
              ],
          },
      };

  @override
  Widget build(BuildContext context) {
    final entries = _entries
        .where((entry) => '${entry.title} ${entry.subtitle} ${entry.status}'
            .toLowerCase()
            .contains(_query.toLowerCase()))
        .toList();
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              children: [
                DetailHeader(
                  icon: widget.workspace == ExchangeWorkspace.admin
                      ? Icons.admin_panel_settings_outlined
                      : Icons.swap_horiz_rounded,
                  title: _title,
                  subtitle: 'Your money, connected.',
                ),
                const SizedBox(height: 24),
                AppCard(
                  color: AppColors.accentSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FRONTEND PREVIEW',
                          style: AppText.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                          switch (widget.workspace) {
                            ExchangeWorkspace.giftCards =>
                              'Turn your cards into spendable money.',
                            ExchangeWorkspace.p2p =>
                              'Trade directly. Follow every step.',
                            ExchangeWorkspace.merchant =>
                              'Your exchange desk, in one place.',
                            ExchangeWorkspace.admin =>
                              'Clear oversight. Accountable decisions.',
                          },
                          style: AppText.detailTitle),
                      const SizedBox(height: 10),
                      Text(
                          'Sample data only. Trading, approvals and settlements are not enabled.',
                          style: AppText.bodyMuted),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < _tabs.length; i++)
                    ChoiceChip(
                      label: Text(_tabs[i]),
                      selected: _tab == i,
                      selectedColor: AppColors.accentSoft,
                      onSelected: (_) => setState(() => _tab = i),
                    ),
                ]),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search this workspace',
                  ),
                ),
                const SizedBox(height: 24),
                Text(_tabs[_tab], style: AppText.sectionTitle),
                const SizedBox(height: 16),
                if (entries.isEmpty)
                  AppCard(
                      child: Text('No matching items. Try another search.',
                          style: AppText.bodyMuted)),
                LayoutBuilder(builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 760 ? 2 : 1;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 16) / columns;
                  return Wrap(spacing: 16, runSpacing: 4, children: [
                    for (final entry in entries)
                      SizedBox(
                          width: width,
                          child: AppCard(
                            onTap: () => Navigator.of(context)
                                .push(MaterialPageRoute<void>(
                              builder: (_) => _EntryDetail(entry: entry),
                            )),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.status,
                                      style: AppText.caption
                                          .copyWith(color: AppColors.accent)),
                                  const SizedBox(height: 12),
                                  Text(entry.title, style: AppText.cardTitle),
                                  const SizedBox(height: 8),
                                  Text(entry.subtitle,
                                      style: AppText.bodyMuted),
                                  const SizedBox(height: 18),
                                  Row(children: [
                                    Text('View details',
                                        style: AppText.caption),
                                    const Spacer(),
                                    Icon(Icons.arrow_forward_rounded,
                                        size: 18,
                                        color: AppColors.textSecondary),
                                  ]),
                                ]),
                          )),
                  ]);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Entry {
  const _Entry(this.title, this.subtitle, this.status, this.detail);
  final String title;
  final String subtitle;
  final String status;
  final String detail;
}

class _EntryDetail extends StatelessWidget {
  const _EntryDetail({required this.entry});
  final _Entry entry;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
            child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            DetailHeader(
                icon: Icons.receipt_long_outlined,
                title: entry.title,
                subtitle: 'Preview details · no live transaction'),
            const SizedBox(height: 24),
            AppCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(entry.status, style: AppText.sectionTitle),
                  const SizedBox(height: 16),
                  Text(entry.detail,
                      style: AppText.bodyMuted.copyWith(height: 1.6)),
                ])),
          ],
        )),
      );
}

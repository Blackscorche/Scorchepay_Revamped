/// The single unified transaction ledger record (spec §17 / §26).
///
/// Every fiat movement, crypto movement, escrow funding/release, savings
/// contribution/withdrawal, and Smart Pay funding-leg writes one of these.
/// Every other screen (Home recent activity, Wallet statements, Insights,
/// Transactions list) is meant to be a filtered/aggregated *view* over this
/// one list, never a separately-maintained collection — that's what keeps
/// numbers from disagreeing between screens.
library;

enum LedgerCategory {
  transfer,
  crypto,
  bill,
  escrow,
  savings,
  smartPay,
  automation,
  fee,
  refund,
}

enum LedgerStatus { pending, completed, failed, reversed }

class LedgerEntry {
  LedgerEntry({
    required this.id,
    required this.timestamp,
    required this.currency,
    required this.amount,
    required this.title,
    required this.subtitle,
    required this.category,
    this.status = LedgerStatus.completed,
    this.groupId,
    this.counterparty,
    this.meta = const {},
  });

  final String id;
  final DateTime timestamp;

  /// Currency/asset code this entry is denominated in — 'NGN', 'USD',
  /// 'BTC', 'USDT', etc.
  final String currency;

  /// Signed amount: positive = credit (money in), negative = debit
  /// (money out). Never a float-precision crypto amount in production,
  /// but a `double` is fine for this local prototype.
  final double amount;

  final String title;
  final String subtitle;
  final LedgerCategory category;
  final LedgerStatus status;

  /// Links two-sided entries together — e.g. a P2P transfer writes one
  /// debit entry for the sender and one credit entry for the recipient,
  /// both sharing a `groupId` so they reconcile as a pair. A Smart Pay
  /// payment shares a `groupId` with its underlying funding-leg debits.
  final String? groupId;

  final String? counterparty;

  /// Free-form extra data — e.g. Smart Pay's funding breakdown, an
  /// escrow/savings/automation record id this entry is linked to, a
  /// biller token, a crypto network, etc.
  final Map<String, dynamic> meta;

  bool get isCredit => amount > 0;

  LedgerEntry copyWith({LedgerStatus? status, Map<String, dynamic>? meta}) {
    return LedgerEntry(
      id: id,
      timestamp: timestamp,
      currency: currency,
      amount: amount,
      title: title,
      subtitle: subtitle,
      category: category,
      status: status ?? this.status,
      groupId: groupId,
      counterparty: counterparty,
      meta: meta ?? this.meta,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'currency': currency,
        'amount': amount,
        'title': title,
        'subtitle': subtitle,
        'category': category.name,
        'status': status.name,
        'groupId': groupId,
        'counterparty': counterparty,
        'meta': meta,
      };

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        currency: json['currency'] as String,
        amount: (json['amount'] as num).toDouble(),
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        category: LedgerCategory.values.byName(json['category'] as String),
        status: LedgerStatus.values.byName(json['status'] as String),
        groupId: json['groupId'] as String?,
        counterparty: json['counterparty'] as String?,
        meta: Map<String, dynamic>.from(json['meta'] as Map? ?? {}),
      );
}

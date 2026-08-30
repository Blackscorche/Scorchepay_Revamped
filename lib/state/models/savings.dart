/// Savings — one shared `SavingsGoal` primitive, differentiated by `type`
/// (spec §13). Funding/withdrawal rules differ per type; the state
/// machine and ledger movement pattern (money actually leaves spendable
/// balance into the goal's held balance) is identical for all of them.
library;

enum SavingsType {
  goal,
  locked,
  emergency,
  roundUp,
  autoSaveFixed,
  autoSavePercent,
  scheduled,
  group,
  stablecoin,
}

class GroupMember {
  GroupMember(
      {required this.username,
      required this.displayName,
      this.hasContributedThisCycle = false,
      this.hasReceivedPayout = false});

  final String username;
  final String displayName;
  bool hasContributedThisCycle;
  bool hasReceivedPayout;

  Map<String, dynamic> toJson() => {
        'username': username,
        'displayName': displayName,
        'hasContributedThisCycle': hasContributedThisCycle,
        'hasReceivedPayout': hasReceivedPayout,
      };

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        hasContributedThisCycle:
            json['hasContributedThisCycle'] as bool? ?? false,
        hasReceivedPayout: json['hasReceivedPayout'] as bool? ?? false,
      );
}

class SavingsGoal {
  SavingsGoal({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    this.target,
    this.current = 0,
    this.targetDate,
    this.lockUntil,
    this.penaltyPct,
    this.apy,
    this.roundUpUnit,
    this.autoSaveAmount,
    this.autoSavePercent,
    this.active = true,
    this.groupMembers,
    this.groupContributionAmount,
    this.groupCycleIndex = 0,
    List<String>? contributionLog,
  }) : contributionLog = contributionLog ?? [];

  final String id;
  String name;
  final SavingsType type;
  final String currency;
  double? target;
  double current;
  DateTime? targetDate;

  /// Locked savings only — funds cannot be withdrawn penalty-free before
  /// this date.
  DateTime? lockUntil;
  double? penaltyPct;

  /// Stablecoin / locked savings — annual yield, disclosed at creation.
  double? apy;

  /// Round-up savings — nearest unit transactions are rounded up to.
  double? roundUpUnit;

  /// Auto-save (fixed) — amount debited on each scheduled run (the
  /// actual scheduling lives on a linked AutomationRule).
  double? autoSaveAmount;

  /// Auto-save (% of income) — percent of each qualifying deposit swept
  /// into this goal.
  double? autoSavePercent;

  bool active;

  /// Group / rotating savings only.
  List<GroupMember>? groupMembers;
  double? groupContributionAmount;
  int groupCycleIndex;

  final List<String> contributionLog;

  bool get isComplete => target != null && current >= target!;
  double get progress =>
      target == null || target == 0 ? 0 : (current / target!).clamp(0, 1);
  bool get isLocked =>
      type == SavingsType.locked &&
      lockUntil != null &&
      DateTime.now().isBefore(lockUntil!);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'currency': currency,
        'target': target,
        'current': current,
        'targetDate': targetDate?.toIso8601String(),
        'lockUntil': lockUntil?.toIso8601String(),
        'penaltyPct': penaltyPct,
        'apy': apy,
        'roundUpUnit': roundUpUnit,
        'autoSaveAmount': autoSaveAmount,
        'autoSavePercent': autoSavePercent,
        'active': active,
        'groupMembers': groupMembers?.map((m) => m.toJson()).toList(),
        'groupContributionAmount': groupContributionAmount,
        'groupCycleIndex': groupCycleIndex,
        'contributionLog': contributionLog,
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
        id: json['id'] as String,
        name: json['name'] as String,
        type: SavingsType.values.byName(json['type'] as String),
        currency: json['currency'] as String,
        target: (json['target'] as num?)?.toDouble(),
        current: (json['current'] as num?)?.toDouble() ?? 0,
        targetDate: json['targetDate'] != null
            ? DateTime.parse(json['targetDate'] as String)
            : null,
        lockUntil: json['lockUntil'] != null
            ? DateTime.parse(json['lockUntil'] as String)
            : null,
        penaltyPct: (json['penaltyPct'] as num?)?.toDouble(),
        apy: (json['apy'] as num?)?.toDouble(),
        roundUpUnit: (json['roundUpUnit'] as num?)?.toDouble(),
        autoSaveAmount: (json['autoSaveAmount'] as num?)?.toDouble(),
        autoSavePercent: (json['autoSavePercent'] as num?)?.toDouble(),
        active: json['active'] as bool? ?? true,
        groupMembers: json['groupMembers'] != null
            ? (json['groupMembers'] as List)
                .map((m) =>
                    GroupMember.fromJson(Map<String, dynamic>.from(m as Map)))
                .toList()
            : null,
        groupContributionAmount:
            (json['groupContributionAmount'] as num?)?.toDouble(),
        groupCycleIndex: json['groupCycleIndex'] as int? ?? 0,
        contributionLog:
            List<String>.from(json['contributionLog'] as List? ?? []),
      );
}

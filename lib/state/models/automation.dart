/// Automation — the rules engine (spec §23). Every "automatic" behaviour
/// in the app (recurring transfers, auto-pay bills, scheduled savings,
/// auto-convert-on-receipt) is one instance of this single primitive.
library;

enum TriggerType { schedule, event }

enum ScheduleFrequency { daily, weekly, monthly }

enum EventTrigger { moneyReceived, balanceThreshold }

enum AutomationActionType { send, payBill, save, convert }

enum RuleRunStatus { success, failed }

enum RuleStatus { active, paused, pausedFailed }

class AutomationRun {
  AutomationRun(
      {required this.at, required this.status, required this.message});

  final DateTime at;
  final RuleRunStatus status;
  final String message;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'status': status.name,
        'message': message,
      };

  factory AutomationRun.fromJson(Map<String, dynamic> json) => AutomationRun(
        at: DateTime.parse(json['at'] as String),
        status: RuleRunStatus.values.byName(json['status'] as String),
        message: json['message'] as String,
      );
}

class AutomationRule {
  AutomationRule({
    required this.id,
    required this.name,
    required this.triggerType,
    required this.actionType,
    required this.amount,
    required this.currency,
    this.scheduleFrequency,
    this.eventTrigger,
    this.eventPercent,
    this.eventMinThreshold,
    this.fixedRecipientUsername,
    this.fixedBillerName,
    this.fixedBillerCustomerId,
    this.savingsGoalId,
    this.convertToCurrency,
    this.fundingSourceOverride,
    this.status = RuleStatus.active,
    this.nextRunAt,
    this.lastRunAt,
    List<AutomationRun>? runLog,
  }) : runLog = runLog ?? [];

  final String id;
  String name;
  final TriggerType triggerType;
  final AutomationActionType actionType;
  double amount;
  final String currency;

  // schedule trigger
  ScheduleFrequency? scheduleFrequency;

  // event trigger
  EventTrigger? eventTrigger;

  /// For event-triggered `save` actions defined as "% of triggering
  /// event's amount" rather than a fixed value.
  double? eventPercent;

  /// Minimum triggering-deposit amount before an event rule fires, so a
  /// ₦50 refund doesn't trigger a percent-of-income save.
  double? eventMinThreshold;

  // action targets
  final String? fixedRecipientUsername;
  final String? fixedBillerName;
  final String? fixedBillerCustomerId;
  final String? savingsGoalId;
  final String? convertToCurrency;

  /// null = use Smart Pay's default funding-source priority; otherwise a
  /// fixed currency code to always fund from.
  final String? fundingSourceOverride;

  RuleStatus status;
  DateTime? nextRunAt;
  DateTime? lastRunAt;
  final List<AutomationRun> runLog;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'triggerType': triggerType.name,
        'actionType': actionType.name,
        'amount': amount,
        'currency': currency,
        'scheduleFrequency': scheduleFrequency?.name,
        'eventTrigger': eventTrigger?.name,
        'eventPercent': eventPercent,
        'eventMinThreshold': eventMinThreshold,
        'fixedRecipientUsername': fixedRecipientUsername,
        'fixedBillerName': fixedBillerName,
        'fixedBillerCustomerId': fixedBillerCustomerId,
        'savingsGoalId': savingsGoalId,
        'convertToCurrency': convertToCurrency,
        'fundingSourceOverride': fundingSourceOverride,
        'status': status.name,
        'nextRunAt': nextRunAt?.toIso8601String(),
        'lastRunAt': lastRunAt?.toIso8601String(),
        'runLog': runLog.map((r) => r.toJson()).toList(),
      };

  factory AutomationRule.fromJson(Map<String, dynamic> json) => AutomationRule(
        id: json['id'] as String,
        name: json['name'] as String,
        triggerType: TriggerType.values.byName(json['triggerType'] as String),
        actionType:
            AutomationActionType.values.byName(json['actionType'] as String),
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
        scheduleFrequency: json['scheduleFrequency'] != null
            ? ScheduleFrequency.values
                .byName(json['scheduleFrequency'] as String)
            : null,
        eventTrigger: json['eventTrigger'] != null
            ? EventTrigger.values.byName(json['eventTrigger'] as String)
            : null,
        eventPercent: (json['eventPercent'] as num?)?.toDouble(),
        eventMinThreshold: (json['eventMinThreshold'] as num?)?.toDouble(),
        fixedRecipientUsername: json['fixedRecipientUsername'] as String?,
        fixedBillerName: json['fixedBillerName'] as String?,
        fixedBillerCustomerId: json['fixedBillerCustomerId'] as String?,
        savingsGoalId: json['savingsGoalId'] as String?,
        convertToCurrency: json['convertToCurrency'] as String?,
        fundingSourceOverride: json['fundingSourceOverride'] as String?,
        status: RuleStatus.values.byName(json['status'] as String),
        nextRunAt: json['nextRunAt'] != null
            ? DateTime.parse(json['nextRunAt'] as String)
            : null,
        lastRunAt: json['lastRunAt'] != null
            ? DateTime.parse(json['lastRunAt'] as String)
            : null,
        runLog: (json['runLog'] as List? ?? [])
            .map((r) =>
                AutomationRun.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList(),
      );
}

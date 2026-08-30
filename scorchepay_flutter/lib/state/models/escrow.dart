/// Escrow — the full state machine (spec §10, walkthrough §5).
///
/// Deliberate policy choices baked into this model, matching the spec's
/// recommended defaults where it explicitly offers a choice:
///  - Multi-milestone escrows collect all milestone funds up front at
///    funding time (simpler, more protective of the seller — the spec
///    flags this as the recommended default).
///  - Review window default is 72 hours.
///  - `currentUserRole` records whether the local demo user is the buyer
///    or the seller on this contract, since this prototype has exactly
///    one real (local) user and a roster of seeded demo counterparties.
library;

enum EscrowStatus {
  draft,
  awaitingFunding,
  funded,
  disputed,
  completed,
  refunded,
  cancelled,
}

enum EscrowRole { buyer, seller }

enum MilestoneStatus {
  pending, // funds collected, not yet started
  inProgress,
  evidenceSubmitted,
  reviewWindow,
  released,
  disputed,
}

enum DisputeResolution { releaseToSeller, refundToBuyer, split }

class EscrowTimelineEvent {
  EscrowTimelineEvent({
    required this.at,
    required this.actor,
    required this.description,
  });

  final DateTime at;
  final String actor;
  final String description;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'actor': actor,
        'description': description,
      };

  factory EscrowTimelineEvent.fromJson(Map<String, dynamic> json) => EscrowTimelineEvent(
        at: DateTime.parse(json['at'] as String),
        actor: json['actor'] as String,
        description: json['description'] as String,
      );
}

class EscrowMilestone {
  EscrowMilestone({
    required this.id,
    required this.description,
    required this.amount,
    this.status = MilestoneStatus.pending,
    this.evidenceNote,
    this.evidenceSubmittedAt,
    this.reviewDeadline,
    this.disputeReason,
  });

  final String id;
  String description;
  final double amount;
  MilestoneStatus status;
  String? evidenceNote;
  DateTime? evidenceSubmittedAt;
  DateTime? reviewDeadline;
  String? disputeReason;

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'status': status.name,
        'evidenceNote': evidenceNote,
        'evidenceSubmittedAt': evidenceSubmittedAt?.toIso8601String(),
        'reviewDeadline': reviewDeadline?.toIso8601String(),
        'disputeReason': disputeReason,
      };

  factory EscrowMilestone.fromJson(Map<String, dynamic> json) => EscrowMilestone(
        id: json['id'] as String,
        description: json['description'] as String,
        amount: (json['amount'] as num).toDouble(),
        status: MilestoneStatus.values.byName(json['status'] as String),
        evidenceNote: json['evidenceNote'] as String?,
        evidenceSubmittedAt: json['evidenceSubmittedAt'] != null ? DateTime.parse(json['evidenceSubmittedAt'] as String) : null,
        reviewDeadline: json['reviewDeadline'] != null ? DateTime.parse(json['reviewDeadline'] as String) : null,
        disputeReason: json['disputeReason'] as String?,
      );
}

class EscrowContract {
  EscrowContract({
    required this.id,
    required this.escrowType,
    required this.counterpartyUsername,
    required this.counterpartyName,
    required this.currentUserRole,
    required this.description,
    required this.currency,
    required this.milestones,
    required this.createdAt,
    this.status = EscrowStatus.draft,
    this.feePct = 0.01,
    List<EscrowTimelineEvent>? timeline,
    this.disputeResolution,
  }) : timeline = timeline ?? [];

  final String id;
  final String escrowType; // Marketplace, Freelance, Business, Property, Vehicle, Digital goods, Physical goods
  final String counterpartyUsername;
  final String counterpartyName;

  /// Whether the local demo user is the buyer or the seller on this
  /// specific contract.
  final EscrowRole currentUserRole;

  final String description;
  final String currency;
  final List<EscrowMilestone> milestones;
  final DateTime createdAt;
  EscrowStatus status;
  final double feePct;
  final List<EscrowTimelineEvent> timeline;
  DisputeResolution? disputeResolution;

  double get totalAmount => milestones.fold(0.0, (sum, m) => sum + m.amount);
  double get fee => totalAmount * feePct;

  bool get isBuyer => currentUserRole == EscrowRole.buyer;

  void log(String actor, String description) {
    timeline.add(EscrowTimelineEvent(at: DateTime.now(), actor: actor, description: description));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'escrowType': escrowType,
        'counterpartyUsername': counterpartyUsername,
        'counterpartyName': counterpartyName,
        'currentUserRole': currentUserRole.name,
        'description': description,
        'currency': currency,
        'milestones': milestones.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'feePct': feePct,
        'timeline': timeline.map((t) => t.toJson()).toList(),
        'disputeResolution': disputeResolution?.name,
      };

  factory EscrowContract.fromJson(Map<String, dynamic> json) => EscrowContract(
        id: json['id'] as String,
        escrowType: json['escrowType'] as String,
        counterpartyUsername: json['counterpartyUsername'] as String,
        counterpartyName: json['counterpartyName'] as String,
        currentUserRole: EscrowRole.values.byName(json['currentUserRole'] as String),
        description: json['description'] as String,
        currency: json['currency'] as String,
        milestones: (json['milestones'] as List).map((m) => EscrowMilestone.fromJson(Map<String, dynamic>.from(m as Map))).toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: EscrowStatus.values.byName(json['status'] as String),
        feePct: (json['feePct'] as num).toDouble(),
        timeline: (json['timeline'] as List).map((t) => EscrowTimelineEvent.fromJson(Map<String, dynamic>.from(t as Map))).toList(),
        disputeResolution: json['disputeResolution'] != null ? DisputeResolution.values.byName(json['disputeResolution'] as String) : null,
      );
}

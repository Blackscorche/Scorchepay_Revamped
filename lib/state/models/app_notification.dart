/// Notifications feed (spec §20). Fires on every state transition that
/// matters to the user — escrow transitions, savings milestones,
/// automation success/failure, incoming money — rather than being a
/// hardcoded static list.
enum NotificationCategory {
  transfers,
  deposits,
  withdrawals,
  crypto,
  escrow,
  bills,
  savings,
  security,
  automation,
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.at,
    required this.category,
    required this.title,
    required this.body,
    this.read = false,
  });

  final String id;
  final DateTime at;
  final NotificationCategory category;
  final String title;
  final String body;
  bool read;

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'category': category.name,
        'title': title,
        'body': body,
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        at: DateTime.parse(json['at'] as String),
        category:
            NotificationCategory.values.byName(json['category'] as String),
        title: json['title'] as String,
        body: json['body'] as String,
        read: json['read'] as bool? ?? false,
      );
}

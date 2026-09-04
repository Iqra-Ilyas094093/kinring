import 'package:cloud_firestore/cloud_firestore.dart';

/// Matches the "kinds" already used by NotificationsScreen's demo list:
/// cleared, snoozed, ring-now, reminder confirmed, group activity — plus
/// eventCreated/profileUpdated for the notification fan-out worker
/// (kinring-notify).
enum NotificationKind { cleared, snoozed, ringNow, reminderConfirmed, groupActivity, eventCreated, profileUpdated }

NotificationKind _kindFromString(String? v) => NotificationKind.values.firstWhere(
      (e) => e.name == v,
      orElse: () => NotificationKind.groupActivity,
    );

/// Firestore doc: `notifications/{uid}/items/{id}`.
class NotificationItem {
  NotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.groupId,
    required this.ts,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String groupId;
  final DateTime ts;

  factory NotificationItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return NotificationItem(
      id: doc.id,
      kind: _kindFromString(d['kind'] as String?),
      title: (d['title'] as String?) ?? '',
      groupId: (d['groupId'] as String?) ?? '',
      ts: (d['ts'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'kind': kind.name,
        'title': title,
        'groupId': groupId,
        'ts': Timestamp.fromDate(ts),
      };
}

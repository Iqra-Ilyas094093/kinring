import 'package:cloud_firestore/cloud_firestore.dart';

import 'event_draft.dart';
import '../widgets/common/event_card.dart';
import '../widgets/common/status_badge.dart';

String repeatRuleToString(RepeatRule r) => r.name; // once/daily/weekly/custom
RepeatRule repeatRuleFromString(String? v) => RepeatRule.values.firstWhere(
      (e) => e.name == v,
      orElse: () => RepeatRule.once,
    );

String eventKindToString(EventKind k) => k.name; // alarm/reminder
EventKind eventKindFromString(String? v) =>
    v == 'reminder' ? EventKind.reminder : EventKind.alarm;

String statusToString(EventMemberStatus s) => s.name;
EventMemberStatus statusFromString(String? v) =>
    EventMemberStatus.values.firstWhere(
      (e) => e.name == v,
      orElse: () => EventMemberStatus.pending,
    );

/// Firestore doc: `groups/{groupId}/events/{eventId}`.
///
/// Named `FirestoreEvent` (not `Event`) to avoid clashing with `dart:core`
/// naming conventions elsewhere in the codebase.
class FirestoreEvent {
  FirestoreEvent({
    required this.id,
    required this.groupId,
    required this.kind,
    required this.title,
    required this.timeUTC,
    required this.repeatRule,
    required this.createdBy,
    this.customDays = const <String>[],
    this.snoozeEnabled = true,
    this.confirmationPhrase = '',
    this.useSimpleTap = true,
    this.cancelled = false,
  });

  final String id;
  final String groupId;
  final EventKind kind;
  final String title;
  final DateTime timeUTC;
  final RepeatRule repeatRule;
  final List<String> customDays;
  final String createdBy;

  // taskConfig fields, flattened (alarm uses snoozeEnabled; reminder uses
  // confirmationPhrase/useSimpleTap) — mirrors EventDraft in the UI layer.
  final bool snoozeEnabled;
  final String confirmationPhrase;
  final bool useSimpleTap;

  final bool cancelled;

  factory FirestoreEvent.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String groupId,
  ) {
    final d = doc.data() ?? const {};
    final task = (d['taskConfig'] as Map?)?.cast<String, dynamic>() ?? const {};
    return FirestoreEvent(
      id: doc.id,
      groupId: groupId,
      kind: eventKindFromString(d['type'] as String?),
      title: (d['title'] as String?) ?? '',
      timeUTC: (d['timeUTC'] as Timestamp?)?.toDate() ?? DateTime.now().toUtc(),
      repeatRule: repeatRuleFromString(d['repeatRule'] as String?),
      customDays: List<String>.from(d['customDays'] as List? ?? const []),
      createdBy: (d['createdBy'] as String?) ?? '',
      snoozeEnabled: (task['snoozeEnabled'] as bool?) ?? true,
      confirmationPhrase: (task['confirmationPhrase'] as String?) ?? '',
      useSimpleTap: (task['useSimpleTap'] as bool?) ?? true,
      cancelled: (d['cancelled'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': eventKindToString(kind),
        'title': title,
        'timeUTC': Timestamp.fromDate(timeUTC),
        'repeatRule': repeatRuleToString(repeatRule),
        'customDays': customDays,
        'createdBy': createdBy,
        'taskConfig': {
          'snoozeEnabled': snoozeEnabled,
          'confirmationPhrase': confirmationPhrase,
          'useSimpleTap': useSimpleTap,
        },
        'cancelled': cancelled,
      };
}

/// Firestore doc: `groups/{groupId}/events/{eventId}/statuses/{uid}`.
class EventStatus {
  EventStatus({
    required this.uid,
    required this.status,
    this.clearedAt,
  });

  final String uid;
  final EventMemberStatus status;
  final DateTime? clearedAt;

  factory EventStatus.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return EventStatus(
      uid: doc.id,
      status: statusFromString(d['status'] as String?),
      clearedAt: (d['clearedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'status': statusToString(status),
        if (clearedAt != null) 'clearedAt': Timestamp.fromDate(clearedAt!),
      };
}

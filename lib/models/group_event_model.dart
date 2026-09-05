import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/common/event_card.dart';
import 'event_draft.dart';

/// `groups/{groupId}/events/{eventId}` — product doc Phase 1 schema.
///
/// `memberIds` is copied from the group at creation time (not in the
/// original doc schema) purely so Home's "Upcoming" list can run a single
/// `collectionGroup('events')` query across every group the user is in,
/// instead of one listener per group. It's a snapshot of membership at
/// creation — doesn't auto-update if someone joins/leaves later (fine for
/// MVP; Phase 8 event-status wiring reads live membership separately).
class GroupEventModel {
  GroupEventModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.memberIds,
    required this.kind,
    required this.title,
    required this.timeUTC,
    required this.repeatRule,
    required this.customDays,
    required this.snoozeEnabled,
    required this.confirmationPhrase,
    required this.useSimpleTap,
    required this.createdBy,
    this.snoozeCount = 0,
  });

  final String id;
  final String groupId;
  final String groupName;
  final List<String> memberIds;
  final EventKind kind;
  final String title;
  final DateTime timeUTC;
  final RepeatRule repeatRule;
  final Set<String> customDays;
  final bool snoozeEnabled;
  final String confirmationPhrase;
  final bool useSimpleTap;
  final String createdBy;

  /// How many times the CURRENT ring cycle has been snoozed — bumped by
  /// [EventsViewModel.snoozeEvent], read back into the re-fired
  /// [EventDraft] (both the client's own local re-schedule and the
  /// kinring-cron backup push) so Color Match's difficulty scaling
  /// survives across a snooze instead of resetting to 0.
  final int snoozeCount;

  factory GroupEventModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String groupId,
  ) {
    final data = doc.data() ?? const {};
    final ts = data['timeUTC'];
    return GroupEventModel(
      id: doc.id,
      groupId: groupId,
      groupName: data['groupName'] as String? ?? '',
      memberIds: List<String>.from(data['memberIds'] as List? ?? const []),
      kind: (data['type'] as String? ?? 'alarm') == 'alarm' ? EventKind.alarm : EventKind.reminder,
      title: data['title'] as String? ?? '',
      timeUTC: ts is Timestamp ? ts.toDate() : DateTime.now(),
      repeatRule: RepeatRule.values.firstWhere(
        (r) => r.name == (data['repeatRule'] as String? ?? 'once'),
        orElse: () => RepeatRule.once,
      ),
      customDays: Set<String>.from(data['customDays'] as List? ?? const []),
      snoozeEnabled: data['snoozeEnabled'] as bool? ?? true,
      confirmationPhrase: data['confirmationPhrase'] as String? ?? '',
      useSimpleTap: data['useSimpleTap'] as bool? ?? true,
      createdBy: data['createdBy'] as String? ?? '',
      snoozeCount: data['snoozeCount'] as int? ?? 0,
    );
  }

  /// Converts to the `EventDraft` the existing screens already render.
  EventDraft toDraft() => EventDraft(
        groupId: groupId,
        groupName: groupName,
        eventId: id,
        kind: kind,
        title: title,
        date: timeUTC.toLocal(),
        time: timeUTC.toLocal(),
        repeatRule: repeatRule,
        customDays: customDays,
        snoozeEnabled: snoozeEnabled,
        confirmationPhrase: confirmationPhrase,
        useSimpleTap: useSimpleTap,
        snoozeCount: snoozeCount,
      );

  static Map<String, dynamic> mapFromDraft({
    required EventDraft draft,
    required List<String> memberIds,
    required String createdBy,
  }) {
    final date = draft.date ?? DateTime.now();
    final time = draft.time ?? DateTime.now();
    final localFire = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return {
      'groupName': draft.groupName,
      'memberIds': memberIds,
      'type': draft.kind == EventKind.alarm ? 'alarm' : 'reminder',
      'title': draft.title,
      'timeUTC': Timestamp.fromDate(localFire.toUtc()),
      'repeatRule': draft.repeatRule.name,
      'customDays': draft.customDays.toList(),
      'snoozeEnabled': draft.snoozeEnabled,
      'confirmationPhrase': draft.confirmationPhrase,
      'useSimpleTap': draft.useSimpleTap,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

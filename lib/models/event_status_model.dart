import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/common/status_badge.dart' show EventMemberStatus;

EventMemberStatus _fromString(String? v) => EventMemberStatus.values.firstWhere(
      (e) => e.name == v,
      orElse: () => EventMemberStatus.pending,
    );

/// `groups/{groupId}/events/{eventId}/statuses/{uid}` — product doc
/// Phase 1 schema, wired in Phase 8. Reuses [EventMemberStatus] (already
/// defined in `status_badge.dart` for the Live Status pill) instead of a
/// second parallel enum.
class EventStatusModel {
  EventStatusModel({
    required this.uid,
    required this.status,
    this.clearedAt,
    this.ringingAt,
    this.forceStoppedByAdmin = false,
  });

  final String uid;
  final EventMemberStatus status;
  final DateTime? clearedAt;
  final DateTime? ringingAt;
  final bool forceStoppedByAdmin;

  factory EventStatusModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final clearedTs = d['clearedAt'];
    final ringingTs = d['ringingAt'];
    return EventStatusModel(
      uid: doc.id,
      status: _fromString(d['status'] as String?),
      clearedAt: clearedTs is Timestamp ? clearedTs.toDate() : null,
      ringingAt: ringingTs is Timestamp ? ringingTs.toDate() : null,
      forceStoppedByAdmin: d['forceStoppedByAdmin'] == true,
    );
  }
}

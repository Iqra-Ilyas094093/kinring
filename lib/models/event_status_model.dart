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
  EventStatusModel({required this.uid, required this.status, this.clearedAt});

  final String uid;
  final EventMemberStatus status;
  final DateTime? clearedAt;

  factory EventStatusModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final ts = d['clearedAt'];
    return EventStatusModel(
      uid: doc.id,
      status: _fromString(d['status'] as String?),
      clearedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

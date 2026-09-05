import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/event_status_model.dart';

/// Phase 8 — task-clear + Live Status wiring (product doc Part 11).
///
/// Unlike [GroupsViewModel]/[EventsViewModel]/[NotificationsViewModel],
/// this is NOT provided once at the app root — its data is scoped to a
/// single event's ringing/status flow, not the whole app session, so
/// screens that need it (Color Match, Type & Confirm, Live Group
/// Status, Event History) just instantiate it directly.
class EventStatusViewModel extends ChangeNotifier {
  EventStatusViewModel({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _statuses(String groupId, String eventId) => _db
      .collection('groups')
      .doc(groupId)
      .collection('events')
      .doc(eventId)
      .collection('statuses');

  /// Called from the Color Match / Type & Confirm task screens once the
  /// task is actually solved. Silently no-ops with no signed-in user or
  /// no real `eventId` — an ad-hoc "Ring Now" broadcast (Phase 7) has no
  /// backing event doc to attach a status to.
  Future<void> markCleared({required String groupId, String? eventId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || eventId == null || groupId.isEmpty) return;
    await _statuses(groupId, eventId).doc(uid).set({
      'status': 'cleared',
      'clearedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Called when the ringing person snoozes instead of clearing —
  /// updates their Live Status badge to "Snoozed" (product doc 5.9.1's
  /// amber pill) instead of leaving them stuck on "Pending" for the
  /// next 5 minutes, which read as if they hadn't even seen the alarm.
  Future<void> markSnoozed({required String groupId, String? eventId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || eventId == null || groupId.isEmpty) return;
    await _statuses(groupId, eventId).doc(uid).set({
      'status': 'snoozed',
    }, SetOptions(merge: true));
  }

  /// Live per-member status for the Live Group Status Screen. A member
  /// with no status doc yet (hasn't opened their task screen) has no
  /// entry here at all — [LiveGroupStatusScreen] merges this against
  /// the group's member list and treats a missing entry as "pending".
  Stream<List<EventStatusModel>> listenStatuses({required String groupId, required String eventId}) {
    return _statuses(groupId, eventId).snapshots().map(
          (qs) => qs.docs.map(EventStatusModel.fromDoc).toList(),
        );
  }

  /// One-time fetch for Event History (Phase 10) — a past event's
  /// statuses don't need a live listener, just a snapshot to compute
  /// the "X/Y cleared" summary and per-member clear times.
  Future<List<EventStatusModel>> fetchStatuses({required String groupId, required String eventId}) async {
    final qs = await _statuses(groupId, eventId).get();
    return qs.docs.map(EventStatusModel.fromDoc).toList();
  }
}

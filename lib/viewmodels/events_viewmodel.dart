import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/event_draft.dart';
import '../models/event_model.dart';
import '../widgets/common/event_card.dart';

/// Event backend (product doc Part 5.7 / roadmap Phase 3 — CRUD only,
/// no firing yet: that's the local-alarm + FCM phases downstream).
///
/// Same pattern as [GroupsViewModel]: screens never talk to `Firestore`
/// directly. Reads are `Stream`s so Home's "Upcoming" list and Group
/// Details' "Upcoming Events" update live the moment an event is
/// created/edited/cancelled anywhere.
class EventsViewModel extends ChangeNotifier {
  EventsViewModel({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('EventsViewModel used while signed out.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _eventsCol(String groupId) =>
      _db.collection('groups').doc(groupId).collection('events');

  // ---- reads (live) -------------------------------------------------------

  /// Upcoming (not-cancelled, not-yet-fired) events for one group — powers
  /// Group Details' "Upcoming Events" section.
  Stream<List<FirestoreEvent>> listenUpcomingEventsForGroup(String groupId) {
    final nowUtc = Timestamp.fromDate(DateTime.now().toUtc());
    return _eventsCol(groupId)
        .where('cancelled', isEqualTo: false)
        .where('timeUTC', isGreaterThanOrEqualTo: nowUtc)
        .orderBy('timeUTC')
        .snapshots()
        .map((snap) => snap.docs.map((d) => FirestoreEvent.fromDoc(d, groupId)).toList());
  }

  /// Upcoming events merged across several groups at once — powers
  /// Home's "Upcoming" section, which spans every group the user is in.
  ///
  /// Firestore security rules can't filter a `collectionGroup('events')`
  /// query down to "only groups I'm a member of" (rules reject the whole
  /// query if any matched doc fails the rule) — so this fans out one
  /// live query per group instead and merges client-side. Re-emits the
  /// full merged, time-sorted list whenever *any* one group's events
  /// change. Caller owns re-subscribing when the group list itself
  /// changes (see `HomeScreen`, which rebuilds this from a group-id
  /// list that's itself live).
  Stream<List<FirestoreEvent>> listenUpcomingEventsAcrossGroups(List<String> groupIds) {
    if (groupIds.isEmpty) return Stream.value(const <FirestoreEvent>[]);

    late final StreamController<List<FirestoreEvent>> controller;
    final latest = <String, List<FirestoreEvent>>{};
    final subs = <StreamSubscription<List<FirestoreEvent>>>[];

    void emitMerged() {
      final merged = latest.values.expand((e) => e).toList()
        ..sort((a, b) => a.timeUTC.compareTo(b.timeUTC));
      controller.add(merged);
    }

    controller = StreamController<List<FirestoreEvent>>.broadcast(
      onListen: () {
        for (final groupId in groupIds) {
          subs.add(listenUpcomingEventsForGroup(groupId).listen((events) {
            latest[groupId] = events;
            emitMerged();
          }));
        }
      },
      onCancel: () {
        for (final s in subs) {
          s.cancel();
        }
      },
    );

    return controller.stream;
  }

  Stream<FirestoreEvent?> watchEvent(String groupId, String eventId) {
    return _eventsCol(groupId)
        .doc(eventId)
        .snapshots()
        .map((doc) => doc.exists ? FirestoreEvent.fromDoc(doc, groupId) : null);
  }

  // ---- writes ---------------------------------------------------------

  /// Writes a new event doc from a Create Event flow draft. [draft.groupId]
  /// must be set (picked on the Create Event screen) — throws otherwise.
  Future<FirestoreEvent> createEvent(EventDraft draft) async {
    final groupId = draft.groupId;
    if (groupId == null) {
      throw StateError('EventDraft.groupId must be set before createEvent — pick a group first.');
    }

    final ref = _eventsCol(groupId).doc();
    final title = draft.title.trim().isNotEmpty
        ? draft.title.trim()
        : (draft.kind == EventKind.alarm ? 'Alarm' : 'Reminder');

    final event = FirestoreEvent(
      id: ref.id,
      groupId: groupId,
      kind: draft.kind,
      title: title,
      timeUTC: draft.toUtcDateTime(),
      repeatRule: draft.repeatRule,
      customDays: draft.customDays.toList(),
      createdBy: _uid,
      snoozeEnabled: draft.snoozeEnabled,
      confirmationPhrase: draft.confirmationPhrase,
      useSimpleTap: draft.useSimpleTap,
    );

    await ref.set(event.toMap());
    return event;
  }

  /// Overwrites an existing event doc from an edited draft. [draft.id] and
  /// [draft.groupId] must both be set (i.e. [EventDraft.isPersisted]).
  Future<void> editEvent(EventDraft draft) async {
    final groupId = draft.groupId;
    final id = draft.id;
    if (groupId == null || id == null) {
      throw StateError('EventDraft.id/groupId must be set before editEvent — not a persisted event.');
    }

    final title = draft.title.trim().isNotEmpty
        ? draft.title.trim()
        : (draft.kind == EventKind.alarm ? 'Alarm' : 'Reminder');

    final event = FirestoreEvent(
      id: id,
      groupId: groupId,
      kind: draft.kind,
      title: title,
      timeUTC: draft.toUtcDateTime(),
      repeatRule: draft.repeatRule,
      customDays: draft.customDays.toList(),
      createdBy: _uid,
      snoozeEnabled: draft.snoozeEnabled,
      confirmationPhrase: draft.confirmationPhrase,
      useSimpleTap: draft.useSimpleTap,
    );

    await _eventsCol(groupId).doc(id).update(event.toMap());
  }

  /// Flags the event cancelled rather than deleting the doc — keeps it
  /// visible in Event History (Phase 10) instead of vanishing outright.
  Future<void> cancelEvent(String groupId, String eventId) async {
    await _eventsCol(groupId).doc(eventId).update({'cancelled': true});
  }
}

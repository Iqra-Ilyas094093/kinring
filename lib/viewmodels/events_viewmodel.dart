import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/services/alarm_permissions_service.dart';
import '../core/services/alarm_scheduler.dart';
import '../core/services/notify_service.dart';
import '../models/event_draft.dart';
import '../models/group_event_model.dart';
import '../models/notification_item.dart';
import '../widgets/common/event_card.dart';

/// Phase 3 — Event CRUD, backed by Firestore. Phase 4 hooks in here too:
/// every successful create/edit (re)schedules the device-local exact
/// alarm, and cancel tears it down — this is the single place Firestore
/// writes and `AlarmScheduler` calls stay in lockstep, so a screen can
/// never write an event without also scheduling (or dropping) its
/// alarm.
class EventsViewModel extends ChangeNotifier {
  EventsViewModel({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('EventsViewModel used with no signed-in user.');
    return uid;
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Every upcoming event across every group the user is in, live —
  /// backs Home's "Upcoming" section. Relies on `memberIds` being
  /// denormalized onto each event doc (see `GroupEventModel`), so this
  /// is one `collectionGroup` query instead of one listener per group.
  Stream<List<GroupEventModel>> listenUpcomingEvents() {
    final now = Timestamp.now();
    return _db
        .collectionGroup('events')
        .where('memberIds', arrayContains: _uid)
        .where('timeUTC', isGreaterThanOrEqualTo: now)
        .orderBy('timeUTC')
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => GroupEventModel.fromDoc(d, d.reference.parent.parent!.id))
            .toList());
  }

  Stream<List<GroupEventModel>> listenGroupEvents(String groupId) {
    final now = Timestamp.now();
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('events')
        .where('timeUTC', isGreaterThanOrEqualTo: now)
        .orderBy('timeUTC')
        .snapshots()
        .map((qs) => qs.docs.map((d) => GroupEventModel.fromDoc(d, groupId)).toList());
  }

  /// Phase 10 — Event History. Everything in `groups/{id}/events` whose
  /// `timeUTC` has already passed, most recent first. `once` events stay
  /// in this collection forever once fired (only `cancelEvent` deletes
  /// them) — the cron worker's `lastFiredAt` marks them done but doesn't
  /// remove the doc, which is exactly what this needs to read them back.
  /// Known gap: a repeating event's `timeUTC` gets advanced to its NEXT
  /// occurrence as soon as the cron worker fires it, so it stops
  /// matching "past" the moment it's fired — repeating events won't show
  /// up here. Fixing that needs a separate per-occurrence log doc,
  /// deliberately out of scope for this pass (see manual steps list).
  Stream<List<GroupEventModel>> listenPastEvents(String groupId, {int limit = 30}) {
    final now = Timestamp.now();
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('events')
        .where('timeUTC', isLessThan: now)
        .orderBy('timeUTC', descending: true)
        .limit(limit)
        .snapshots()
        .map((qs) => qs.docs.map((d) => GroupEventModel.fromDoc(d, groupId)).toList());
  }

  Stream<GroupEventModel?> listenEvent(String groupId, String eventId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('events')
        .doc(eventId)
        .snapshots()
        .map((doc) => doc.exists ? GroupEventModel.fromDoc(doc, groupId) : null);
  }

  /// [memberIds] should be the group's current `memberIds` (from
  /// `GroupsViewModel.listenGroups`/`listenGroup`) — pass it in rather
  /// than re-fetching here, since the caller already has it live.
  Future<String?> createEvent(EventDraft draft, {required List<String> memberIds}) async {
    try {
      final ref = _db
          .collection('groups')
          .doc(draft.groupId)
          .collection('events')
          .doc();
      await ref.set(GroupEventModel.mapFromDraft(
        draft: draft,
        memberIds: memberIds,
        createdBy: _uid,
      ));

      // Phase 4: schedule the local exact alarm now that the event has
      // a real id. Permission requests are contextual (first time this
      // runs, per event kind) — a no-op if already granted. Kept in its
      // own try/catch: the Firestore write already succeeded, so a
      // scheduling failure (e.g. permission denied) shouldn't be
      // reported back as "event creation failed" — the event exists,
      // it just won't ring locally until the permission issue's fixed.
      draft.eventId = ref.id;
      try {
        await AlarmPermissionsService.requestContextualPermissions();
        await AlarmScheduler.scheduleForEvent(draft);
      } catch (e) {
        debugPrint('AlarmScheduler.scheduleForEvent failed: $e');
      }

      NotifyService.notify(
        groupId: draft.groupId,
        kind: NotificationKind.eventCreated.name,
        title: 'New ${draft.kind.name}: ${draft.title.isEmpty ? (draft.kind == EventKind.alarm ? 'Alarm' : 'Reminder') : draft.title}',
      );

      return ref.id;
    } catch (e) {
      _errorMessage = 'Could not create event. Please try again.';
      notifyListeners();
      return null;
    }
  }

  /// Phase 7 (amended) — lightweight event doc for an ad-hoc "Ring Now"
  /// broadcast. No local `AlarmScheduler` call (unlike [createEvent]) —
  /// the broadcast is instant, not something to arm the device for
  /// later — but it DOES get a real Firestore doc, so the same
  /// `statuses` subcollection (Phase 8) and Event History (Phase 10)
  /// work for it exactly like a scheduled event. Previously Ring Now
  /// had no backing doc at all, so [EventStatusViewModel.markCleared]
  /// silently no-opped and Live Status stayed "Pending" forever.
  Future<String?> createBroadcastEvent({
    required String groupId,
    required List<String> memberIds,
  }) async {
    try {
      final ref = _db.collection('groups').doc(groupId).collection('events').doc();
      await ref.set({
        'type': 'alarm',
        'title': 'Ring Now Broadcast',
        'timeUTC': Timestamp.now(),
        'repeatRule': 'once',
        'customDays': <String>[],
        'snoozeEnabled': false,
        'confirmationPhrase': '',
        'useSimpleTap': true,
        'memberIds': memberIds,
        'createdBy': _uid,
      });
      return ref.id;
    } catch (e) {
      _errorMessage = 'Could not start broadcast. Please try again.';
      notifyListeners();
      return null;
    }
  }

  /// Snooze (product doc 5.9's "Snooze Confirmation" dialog, wired for
  /// real here). Bumps the event's `timeUTC` forward by [delay] — which
  /// re-opens it for `kinring-cron`'s existing idempotency check
  /// (`lastFiredAt >= timeUTC` no longer holds once `timeUTC` moves past
  /// it), so the SAME cron backup mechanism that already pushes to
  /// every member re-fires the alarm for the WHOLE group when the delay
  /// elapses — not just this device — without needing any new backend
  /// worker. Also bumps `snoozeCount` (read back into the re-fired
  /// [EventDraft] for difficulty scaling) and marks this member's own
  /// status `snoozed` (the doc's amber "Snoozed" badge existed in the
  /// UI already but nothing ever wrote this status until now).
  ///
  /// Only meaningful for a real persisted event — an ad-hoc Ring Now
  /// broadcast (Phase 7) has `snoozeEnabled: false` on its draft, so the
  /// Snooze button never shows for one; this is not called for those.
  Future<bool> snoozeEvent({
    required String groupId,
    required String eventId,
    required int newSnoozeCount,
    Duration delay = const Duration(minutes: 5),
  }) async {
    try {
      final snoozeUntil = DateTime.now().add(delay);
      final batch = _db.batch();
      batch.update(_db.collection('groups').doc(groupId).collection('events').doc(eventId), {
        'timeUTC': Timestamp.fromDate(snoozeUntil),
        'snoozeCount': newSnoozeCount,
      });
      batch.set(
        _db
            .collection('groups')
            .doc(groupId)
            .collection('events')
            .doc(eventId)
            .collection('statuses')
            .doc(_uid),
        {'status': 'snoozed'},
        SetOptions(merge: true),
      );
      await batch.commit();
      return true;
    } catch (e) {
      _errorMessage = 'Could not snooze. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> editEvent(EventDraft draft) async {
    final eventId = draft.eventId;
    if (eventId == null) {
      throw ArgumentError('editEvent requires draft.eventId — use createEvent for new events.');
    }
    try {
      final date = draft.date ?? DateTime.now();
      final time = draft.time ?? DateTime.now();
      final localFire = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      await _db
          .collection('groups')
          .doc(draft.groupId)
          .collection('events')
          .doc(eventId)
          .update({
        'title': draft.title,
        'timeUTC': Timestamp.fromDate(localFire.toUtc()),
        'repeatRule': draft.repeatRule.name,
        'customDays': draft.customDays.toList(),
        'snoozeEnabled': draft.snoozeEnabled,
        'confirmationPhrase': draft.confirmationPhrase,
        'useSimpleTap': draft.useSimpleTap,
      });

      // Phase 4: time/repeat/task may have changed — cancel the old
      // alarm and schedule fresh rather than trying to diff what moved.
      try {
        await AlarmScheduler.scheduleForEvent(draft);
      } catch (e) {
        debugPrint('AlarmScheduler.scheduleForEvent failed: $e');
      }

      return true;
    } catch (e) {
      _errorMessage = 'Could not save changes. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelEvent(String groupId, String eventId) async {
    try {
      await _db.collection('groups').doc(groupId).collection('events').doc(eventId).delete();
      try {
        await AlarmScheduler.cancelForEvent(eventId);
      } catch (e) {
        debugPrint('AlarmScheduler.cancelForEvent failed: $e');
      }
      return true;
    } catch (e) {
      _errorMessage = 'Could not cancel event. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

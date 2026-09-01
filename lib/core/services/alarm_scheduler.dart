import 'dart:convert';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';

import '../../models/event_draft.dart';
import '../../widgets/common/event_card.dart' show EventKind;
import 'local_notifications_service.dart';
import 'repeat_schedule.dart';

/// Phase 4 — local exact alarm (device-side trigger, works offline).
///
/// Each event's alarm is scheduled directly on the device via Android's
/// `AlarmManager` (through `android_alarm_manager_plus`) — this is the
/// *primary* trigger the doc's Part 3 talks about; the Cloudflare cron
/// worker (Phase 6) is a secondary sync/backup layer on top of this,
/// not a replacement for it, so alarms must keep firing with the app
/// fully killed and the device offline.
///
/// Not a ViewModel — nothing here is UI state. `EventsViewModel` calls
/// into this right after a Firestore write succeeds (create/edit/cancel
/// event), same shape as `GoogleAuthService` being called from
/// `AuthViewModel`.
class AlarmScheduler {
  AlarmScheduler._();

  static Future<void> initialize() => AndroidAlarmManager.initialize();

  /// Stable per-event alarm id — `AlarmManager` ids are ints, Firestore
  /// doc ids are strings, so this is a deterministic hash. Collisions
  /// are astronomically unlikely for this app's scale (one alarm id
  /// space per device, not global), and even a collision just means one
  /// event's alarm gets overwritten/cancelled instead of firing twice —
  /// not silently dropped.
  static int alarmIdFor(String eventId) => eventId.hashCode & 0x7fffffff;

  /// Schedules (or replaces, if already scheduled) the next fire for
  /// this event. Safe to call from both create and edit — always
  /// cancels any existing alarm for this `eventId` first.
  static Future<void> scheduleForEvent(EventDraft draft) async {
    final eventId = draft.eventId;
    if (eventId == null || draft.groupId.isEmpty) {
      throw ArgumentError('scheduleForEvent requires a persisted draft (groupId + eventId set).');
    }
    await cancelForEvent(eventId);

    final date = draft.date ?? DateTime.now();
    final time = draft.time ?? DateTime.now();
    final fireAt = RepeatSchedule.firstOccurrence(
      baseDate: date,
      hour: time.hour,
      minute: time.minute,
      repeatRule: draft.repeatRule,
      customDays: draft.customDays,
    );

    await AndroidAlarmManager.oneShotAt(
      fireAt,
      alarmIdFor(eventId),
      alarmFireCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      alarmClock: true, // shows the OS "next alarm" indicator, exempt from Doze
      params: {'payload': jsonEncode(draft.toJson())},
    );
  }

  static Future<void> cancelForEvent(String eventId) async {
    await AndroidAlarmManager.cancel(alarmIdFor(eventId));
    await LocalNotificationsService.dismiss(alarmIdFor(eventId));
  }
}

/// Top-level, `@pragma('vm:entry-point')` — required by
/// `android_alarm_manager_plus`: this runs in its own headless
/// background isolate spawned by the OS, completely separate from the
/// app's main isolate/widget tree (which may not even be running). It
/// cannot touch `Navigator`/`BuildContext` directly — see
/// `LocalNotificationsService` for how the actual Ringing/Task UI gets
/// reached from here.
@pragma('vm:entry-point')
void alarmFireCallback(int id, Map<String, dynamic> params) async {
  WidgetsFlutterBinding.ensureInitialized();

  final payloadJson = params['payload'] as String?;
  if (payloadJson == null) return;
  final json = jsonDecode(payloadJson) as Map<String, dynamic>;
  final draft = EventDraft.fromJson(json);

  await LocalNotificationsService.showAlarmNotification(
    id: id,
    title: draft.kind == EventKind.alarm ? '⏰ ${draft.title.isEmpty ? "Alarm" : draft.title}' : draft.title.isEmpty ? 'Reminder' : draft.title,
    body: draft.groupName,
    payloadJson: payloadJson,
  );

  final next = RepeatSchedule.nextAfterFire(
    firedAt: DateTime.now(),
    repeatRule: draft.repeatRule,
    customDays: draft.customDays,
  );
  if (next != null) {
    await AndroidAlarmManager.oneShotAt(
      next,
      id,
      alarmFireCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      alarmClock: true,
      params: {'payload': payloadJson},
    );
  }
}

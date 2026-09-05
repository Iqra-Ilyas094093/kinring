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

  /// Stable per-event PRE-ALERT alarm id — deliberately different from
  /// [alarmIdFor] (same eventId, different derived id) so the two never
  /// collide/overwrite each other in `AlarmManager`.
  static int preAlertIdFor(String eventId) => '$eventId:prealert'.hashCode & 0x7fffffff;

  /// How long before the real fire the heads-up warning goes out —
  /// "30 min left for this reminder" per the request. A single fixed
  /// lead time, not (yet) configurable per-event.
  static const preAlertLeadTime = Duration(minutes: 30);

  /// Schedules (or cancels, if now too close) the pre-alert alongside
  /// the main alarm. Silently skips if [fireAt] minus [preAlertLeadTime]
  /// has already passed — no point warning about something 30 minutes
  /// out when the event itself is less than 30 minutes away.
  static Future<void> _schedulePreAlert(EventDraft draft, DateTime fireAt) async {
    final eventId = draft.eventId;
    if (eventId == null) return;
    final preAlertAt = fireAt.subtract(preAlertLeadTime);
    final preAlertId = preAlertIdFor(eventId);

    await AndroidAlarmManager.cancel(preAlertId);
    if (!preAlertAt.isAfter(DateTime.now())) return;

    await AndroidAlarmManager.oneShotAt(
      preAlertAt,
      preAlertId,
      preAlertFireCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: {'payload': jsonEncode(draft.toJson())},
    );
  }

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
    await _schedulePreAlert(draft, fireAt);
  }

  static Future<void> cancelForEvent(String eventId) async {
    await AndroidAlarmManager.cancel(alarmIdFor(eventId));
    await LocalNotificationsService.dismiss(alarmIdFor(eventId));
    await AndroidAlarmManager.cancel(preAlertIdFor(eventId));
    await LocalNotificationsService.dismiss(preAlertIdFor(eventId));
  }

  /// A snooze's local re-fire — one-shot at [fireAt] (the snoozeUntil
  /// time [EventsViewModel.snoozeEvent] just wrote to Firestore), same
  /// alarm id as the original (so it correctly replaces/collapses with
  /// itself, same as any other reschedule) and the SAME
  /// `alarmFireCallback` entry point everything else uses. This is the
  /// snoozing device's own offline-safe guarantee — the rest of the
  /// group is reached via kinring-cron picking up the moved `timeUTC`
  /// instead, since their devices have nothing locally scheduled for a
  /// `once` event after its first fire.
  static Future<void> scheduleSnoozeFor(EventDraft draft, DateTime fireAt) async {
    final eventId = draft.eventId;
    if (eventId == null) return;
    await AndroidAlarmManager.oneShotAt(
      fireAt,
      alarmIdFor(eventId),
      alarmFireCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      alarmClock: true,
      params: {'payload': jsonEncode(draft.toJson())},
    );
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

  final title = draft.kind == EventKind.alarm
      ? '⏰ ${draft.title.isEmpty ? "Alarm" : draft.title}'
      : (draft.title.isEmpty ? 'Reminder' : draft.title);

  if (draft.kind == EventKind.alarm) {
    await LocalNotificationsService.showAlarmNotification(
      id: id,
      title: title,
      body: draft.groupName,
      payloadJson: payloadJson,
    );
  } else {
    // Was unconditionally calling showAlarmNotification before — a
    // locally-scheduled Reminder got the full-screen/ongoing/fullScreenIntent
    // treatment meant only for Alarm kind, instead of the plain heads-up
    // showReminderNotification already used by the FCM path for the
    // exact same kind (fcm_service.dart's background handler branches on
    // `type` correctly; this local path just never matched it).
    await LocalNotificationsService.showReminderNotification(
      id: id,
      title: title,
      body: draft.groupName,
      payloadJson: payloadJson,
    );
  }

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
    // Keeps the "30 min left" heads-up alive across repeats too — a
    // daily/weekly event's pre-alert needs re-arming for each new
    // occurrence, same as the main alarm itself does on this branch.
    await AlarmScheduler._schedulePreAlert(draft, next);
  }
}

/// Top-level, `@pragma('vm:entry-point')` — same constraints as
/// [alarmFireCallback], separate entry point so a pre-alert firing can
/// never be confused with the real alarm/reminder fire (different id,
/// different notification, no full-screen gate, no task/status wiring —
/// this is purely an informational heads-up).
@pragma('vm:entry-point')
void preAlertFireCallback(int id, Map<String, dynamic> params) async {
  WidgetsFlutterBinding.ensureInitialized();

  final payloadJson = params['payload'] as String?;
  if (payloadJson == null) return;
  final draft = EventDraft.fromJson(jsonDecode(payloadJson) as Map<String, dynamic>);

  final minutes = AlarmScheduler.preAlertLeadTime.inMinutes;
  await LocalNotificationsService.showPreAlertNotification(
    id: id,
    title: '⏳ $minutes min left',
    body: '${draft.title.isEmpty ? (draft.kind == EventKind.alarm ? "Alarm" : "Reminder") : draft.title} · ${draft.groupName}',
    groupId: draft.groupId,
  );
}

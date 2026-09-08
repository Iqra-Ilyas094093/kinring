import 'package:flutter/material.dart';

import '../../models/event_draft.dart';
import '../../ui/ringing/alarm_ringing_screen.dart';
import '../../ui/ringing/reminder_notification_card_screen.dart';
import '../../widgets/common/event_card.dart';
import 'alarm_audio_service.dart';

/// Single entry point into the Ringing/Task flow (doc 5.8).
///
/// This is the ONE place the ringing/reminder screen actually appears on
/// screen, regardless of which path got here — local AlarmManager fire,
/// FCM foreground direct-navigation (`FcmService._handleForegroundMessage`
/// skips the notification entirely for alarm/reminder), a notification
/// tap, or an admin "Ring Now"/event-detail preview. Sound/vibration is
/// triggered HERE, not only in `LocalNotificationsService.showAlarmNotification`
/// — that call only covers the background-isolate/notification path;
/// without also covering this one, any path that reaches the screen
/// without going through that notification call (e.g. FCM foreground)
/// shows the screen with no sound, which is exactly the bug this fixes.
/// Restarting an already-looping sound (e.g. user taps a notification
/// that already started it) is harmless — `playAlarmSound` stops any
/// existing playback before restarting.
class EventTrigger {
  EventTrigger._();

  /// The eventId (or a synthetic key for eventId-less drafts) whose
  /// ringing/task flow is currently on screen — guards against pushing
  /// a SECOND `AlarmRingingScreen`/`ReminderNotificationCardScreen` for
  /// the same event when it's already showing. Belt-and-suspenders
  /// alongside `LocalNotificationsService`'s own dedup: that one stops
  /// the underlying notification from re-firing `fullScreenIntent`, this
  /// one stops a stray extra call to `fire()` (any caller, any path)
  /// from double-pushing the route even if it does happen.
  static String? _activeKey;

  static String _keyFor(EventDraft draft) => draft.eventId ?? '${draft.groupId}:${draft.title}';

  static void fire(BuildContext context, EventDraft draft) {
    final key = _keyFor(draft);
    if (key == _activeKey) return;
    _activeKey = key;

    if (draft.kind == EventKind.alarm) {
      AlarmAudioService.playAlarmSound();
    } else {
      AlarmAudioService.vibrateReminder();
    }

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => draft.kind == EventKind.alarm
            ? AlarmRingingScreen(draft: draft)
            : ReminderNotificationCardScreen(draft: draft),
      ),
    )
        .whenComplete(() {
      if (_activeKey == key) _activeKey = null;
      if (draft.kind == EventKind.alarm) {
        AlarmAudioService.stopAlarmSound();
      }
    });
  }
}
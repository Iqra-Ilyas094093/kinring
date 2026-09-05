import 'package:flutter/material.dart';

import '../../models/event_draft.dart';
import '../../ui/ringing/alarm_ringing_screen.dart';
import '../../ui/ringing/reminder_notification_card_screen.dart';
import '../../widgets/common/event_card.dart';

/// Single entry point into the Ringing/Task flow (doc 5.8).
///
/// TODO(backend wiring): call `EventTrigger.fire` from two places once
/// wired: (1) the Android `AlarmManager` receiver, for the primary
/// scheduled trigger — Alarm kind opens straight into
/// [AlarmRingingScreen]; (2) the FCM background/foreground handler, for
/// "Ring Now" broadcasts and for Reminder kind (which is push-only, no
/// full-screen gate). Until then, `AdminPanelScreen._ringNow` and
/// `UpcomingEventDetailScreen`'s preview action call this same function,
/// so the exact UI backend will trigger is already reachable and testable.
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
    });
  }
}

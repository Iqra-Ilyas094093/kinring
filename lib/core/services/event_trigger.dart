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

  static void fire(BuildContext context, EventDraft draft) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => draft.kind == EventKind.alarm
            ? AlarmRingingScreen(draft: draft)
            : ReminderNotificationCardScreen(draft: draft),
      ),
    );
  }
}

import 'package:permission_handler/permission_handler.dart';

import 'local_notifications_service.dart';

/// Requests the three permissions Phase 4's exact-alarm flow needs —
/// exact-alarm scheduling, battery-optimization exemption, and
/// notifications (for the full-screen alarm intent). Requested
/// contextually the first time the user creates an event (doc Phase 4
/// step 5 / Part 5.1 note), not as an upfront onboarding step.
///
/// Each `.request()` call is a no-op if already granted, so this is
/// safe to call on every `createEvent`, not just the very first one.
class AlarmPermissionsService {
  AlarmPermissionsService._();

  static Future<void> requestContextualPermissions() async {
    await LocalNotificationsService.requestPermission();
    await Permission.scheduleExactAlarm.request();
    await Permission.ignoreBatteryOptimizations.request();
  }

  /// Surface this in UI (e.g. a "Permission Denied Warning" dialog, doc
  /// Part 7 #6) if the user needs to be sent to system settings —
  /// `.request()` alone can't recover from a permanently-denied state.
  static Future<bool> hasExactAlarmPermission() => Permission.scheduleExactAlarm.isGranted;
}

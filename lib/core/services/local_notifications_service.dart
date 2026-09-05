import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/event_draft.dart';
import 'event_trigger.dart';
import '../../ui/home/notifications_screen.dart';

/// Wraps `flutter_local_notifications`. `AndroidAlarmManager`'s fire
/// callback runs in a headless background isolate with no widget tree,
/// so it can't push a route directly — this is the bridge: it shows a
/// `fullScreenIntent` notification (category `alarm`), which Android
/// itself launches full-screen over the lock screen, same mechanism
/// real alarm-clock apps use. Tapping the (non-full-screen / heads-up)
/// notification does the same thing when the device was already
/// unlocked/foregrounded.
///
/// This is a "service" in the MVVM sense — no ViewModel owns it, it's a
/// thin platform wrapper other services (`AlarmScheduler`) call into.
class LocalNotificationsService {
  LocalNotificationsService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Versioned to force a fresh channel: Android notification channels
  /// are immutable once created on-device — changing `playSound`/
  /// `enableVibration` etc. in this file does nothing for anyone who
  /// already has an OLDER version of this channel from a previous
  /// install/build, which is very likely why sound wasn't working at
  /// all despite the code asking for it. A new channel id is the only
  /// reliable way to make a settings change actually take effect.
  static const _alarmSoundChannelId = 'kinring_alarm_sound_v2';

  /// A second, separate alarm channel with NO sound — this is what the
  /// "Alarm sounds" setting toggles between (channel SELECTION, not an
  /// in-place mutation, since Android won't allow the latter). Both
  /// still vibrate, both still full-screen; only the audio differs.
  static const _alarmSilentChannelId = 'kinring_alarm_silent_v2';

  /// Reminders' own channel — previously reminders were posted to the
  /// SAME channel as alarms (`_channelId` above, now the alarm-sound
  /// channel), so they silently inherited whatever sound/vibration the
  /// alarm channel had instead of being their own distinct thing. No
  /// sound, vibration only, per this request.
  static const _reminderChannelId = 'kinring_reminder_v2';

  /// Ids currently showing a `fullScreenIntent` alarm. Guards against the
  /// exact bug this was added to fix: the local `AlarmManager` trigger
  /// (Phase 4) and the Cloudflare cron backup push (Phase 6) can both
  /// land within moments of each other for the same event — by design,
  /// the backup is meant to be redundant-but-harmless. But calling
  /// `_plugin.show(...)` a SECOND time with `fullScreenIntent: true`
  /// re-delivers Android's full-screen PendingIntent even for the same
  /// notification id, which relaunches/recreates the top activity —
  /// visible as a white flash (the native launch theme, briefly, during
  /// that recreate) followed by the ringing screen reappearing. Only the
  /// FIRST `show()` for a given id gets `fullScreenIntent: true`; later
  /// calls for the same id (still-active) just refresh the notification
  /// content silently. Cleared in [dismiss] so the NEXT real fire (a
  /// repeat event, or this one after being cancelled/edited) can
  /// full-screen-launch again correctly.
  static final Set<int> _fullScreenShown = {};

  /// Group activity channel (member joined, event created, profile
  /// updated) — separate from [_channelId] since it's a normal
  /// heads-up, never `fullScreenIntent`/`ongoing`.
  static const _activityChannelId = 'kinring_activity';

  /// Payload prefix marking an activity notification's payload as "not
  /// an EventDraft" — [_route] checks for this before trying to
  /// `jsonDecode` it as one.
  static const _activityPayloadPrefix = 'activity:';

  /// Same idea for the "30 min left" pre-alert (see
  /// `AlarmScheduler.preAlertFireCallback`) — its payload is a bare
  /// groupId, not a full `EventDraft`, so it must never be handed to
  /// `EventDraft.fromJson` either.
  static const _preAlertPayloadPrefix = 'prealert:';

  static Future<void> initialize({required GlobalKey<NavigatorState> navigatorKey}) async {
    _navigatorKey = navigatorKey;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: onBackgroundTap,
    );

    const soundChannel = AndroidNotificationChannel(
      _alarmSoundChannelId,
      'Alarms (sound)',
      description: 'KinRing group alarms — audible',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    const silentChannel = AndroidNotificationChannel(
      _alarmSilentChannelId,
      'Alarms (silent)',
      description: 'KinRing group alarms — vibration only, no sound',
      importance: Importance.max,
      playSound: false,
      enableVibration: true,
    );
    const reminderChannel = AndroidNotificationChannel(
      _reminderChannelId,
      'Reminders',
      description: 'KinRing group reminders — vibration only, no sound',
      importance: Importance.high,
      playSound: false,
      enableVibration: true,
    );
    const activityChannel = AndroidNotificationChannel(
      _activityChannelId,
      'Group Activity',
      description: 'Members joining, new events, profile updates',
      importance: Importance.defaultImportance,
    );
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(soundChannel);
    await androidPlugin?.createNotificationChannel(silentChannel);
    await androidPlugin?.createNotificationChannel(reminderChannel);
    await androidPlugin?.createNotificationChannel(activityChannel);
  }

  /// Android 13+ requires this to be requested at runtime, contextually
  /// (doc Phase 4 step 5) — called from `AlarmPermissionsService`.
  /// Android 13+ requires this to be requested at runtime, contextually
  /// (doc Phase 4 step 5) — called from `AlarmPermissionsService`.
  static Future<bool?> requestPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission();
    }
    return false;
  }


  /// Called from [AlarmScheduler]'s fire callback (background isolate).
  /// Always shows — an alarm's full-screen gate isn't something the
  /// "Alarm sounds" setting should be able to suppress entirely, only
  /// its audio. Picks between the two real alarm channels (sound vs
  /// silent) based on the setting — channel SELECTION, since Android
  /// won't let a single channel's sound be toggled per-call (see the
  /// channel ids' doc comments). Both channels vibrate; "Vibration"
  /// isn't separately toggleable for the same reason — an alarm should
  /// always be felt at minimum.
  static Future<void> showAlarmNotification({
    required int id,
    required String title,
    required String body,
    required String payloadJson,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final soundsOn = prefs.getBool('notif_alarm_sounds') ?? true;
    final volume = prefs.getDouble('notif_volume') ?? 0.8;
    final channelId = (soundsOn && volume > 0) ? _alarmSoundChannelId : _alarmSilentChannelId;

    // See _fullScreenShown's doc comment — only the first show() for
    // this id gets to full-screen-launch; a near-duplicate (cron backup
    // arriving right after the local trigger) just refreshes silently.
    final alreadyShown = !_fullScreenShown.add(id);

    final details = AndroidNotificationDetails(
      channelId,
      channelId == _alarmSoundChannelId ? 'Alarms (sound)' : 'Alarms (silent)',
      channelDescription: 'KinRing group alarms',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: !alreadyShown,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
    );
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: details),
      payload: payloadJson,
    );
  }

  /// Phase 5 — reminder push (doc 5.8.4). Unlike [showAlarmNotification]
  /// this is a normal heads-up notification, not `fullScreenIntent`/
  /// `ongoing` — Reminder kind is push-only and never gates the screen.
  /// Tapping it routes through the same `payload` → [EventTrigger.fire]
  /// path, landing on [ReminderNotificationCardScreen] via `EventDraft.kind`.
  /// Posted to its OWN channel (vibration only, no sound) — previously
  /// this shared the alarm channel, so a reminder inherited the alarm's
  /// audio treatment instead of being the quieter, vibration-only nudge
  /// it's supposed to be.
  ///
  /// Gated by Notification Settings' "Reminder notifications" toggle —
  /// unlike alarm sound (above), turning this off means "don't show me
  /// these at all", since a reminder (unlike an alarm) is soft by
  /// design and safe to fully suppress.
  static Future<void> showReminderNotification({
    required int id,
    required String title,
    required String body,
    required String payloadJson,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notif_reminder_notifications') ?? true)) return;

    const details = AndroidNotificationDetails(
      _reminderChannelId,
      'Reminders',
      channelDescription: 'KinRing group reminders — vibration only, no sound',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    );
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: details),
      payload: payloadJson,
    );
  }

  /// Group activity — member joined, new event, profile updated
  /// (kinring-notify Worker push, `type: 'activity'`). Gated by
  /// Notification Settings' "Group activity updates" toggle. Tapping
  /// opens the Notifications screen (the Firestore doc kinring-notify
  /// already wrote is what that screen reads — this is just the live
  /// heads-up, same relationship as the alarm/reminder paths above vs.
  /// their own Firestore-backed screens).
  static Future<void> showActivityNotification({
    required int id,
    required String title,
    required String groupId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notif_group_activity_updates') ?? true)) return;

    const details = AndroidNotificationDetails(
      _activityChannelId,
      'Group Activity',
      channelDescription: 'Members joining, new events, profile updates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    await _plugin.show(
      id,
      title,
      null,
      const NotificationDetails(android: details),
      payload: '$_activityPayloadPrefix$groupId',
    );
  }

  static Future<void> dismiss(int id) {
    _fullScreenShown.remove(id);
    return _plugin.cancel(id);
  }

  /// "30 min left" heads-up (`AlarmScheduler.preAlertFireCallback`) —
  /// purely informational: no full-screen gate, no task/status wiring,
  /// posted to the reminder channel (vibration only, no sound) since a
  /// 30-minutes-out warning shouldn't be as jarring as the alarm itself
  /// firing. Tapping it just opens the app to Home — see [_route]'s
  /// `_preAlertPayloadPrefix` branch — there's no dedicated screen for
  /// "here's the event this warned you about" yet.
  static Future<void> showPreAlertNotification({
    required int id,
    required String title,
    required String body,
    required String groupId,
  }) async {
    const details = AndroidNotificationDetails(
      _reminderChannelId,
      'Reminders',
      channelDescription: 'KinRing group reminders — vibration only, no sound',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: details),
      payload: '$_preAlertPayloadPrefix$groupId',
    );
  }

  /// Cold-start case: app was fully killed, user tapped the alarm
  /// notification, which launched the app. Call once from `main()`
  /// after `initialize`.
  static Future<void> routeIfLaunchedFromNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final payload = details?.notificationResponse?.payload;
    if (details?.didNotificationLaunchApp == true && payload != null) {
      _route(payload);
    }
  }

  static void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) _route(payload);
  }

  /// Must be a top-level/static function, `@pragma('vm:entry-point')` —
  /// the plugin invokes it in a background isolate when the user taps
  /// the notification while the app isn't running in the foreground.
  @pragma('vm:entry-point')
  static void onBackgroundTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) _route(payload);
  }

  static void _route(String payloadJson) {
    final context = _navigatorKey?.currentState?.context;
    if (context == null) return; // App not attached yet — cold-start path handles this via routeIfLaunchedFromNotification instead.
    if (payloadJson.startsWith(_activityPayloadPrefix)) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      return;
    }
    if (payloadJson.startsWith(_preAlertPayloadPrefix)) {
      // No dedicated screen for this yet — tapping it just opens the
      // app to wherever it already lands (Home, via the normal
      // signed-in initial route), rather than crashing on
      // `EventDraft.fromJson` with a payload that was never JSON.
      return;
    }
    final draft = EventDraft.fromJson(jsonDecode(payloadJson) as Map<String, dynamic>);
    EventTrigger.fire(context, draft);
  }
}

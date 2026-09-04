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

  static const _channelId = 'kinring_alarms';

  /// Group activity channel (member joined, event created, profile
  /// updated) — separate from [_channelId] since it's a normal
  /// heads-up, never `fullScreenIntent`/`ongoing`.
  static const _activityChannelId = 'kinring_activity';

  /// Payload prefix marking an activity notification's payload as "not
  /// an EventDraft" — [_route] checks for this before trying to
  /// `jsonDecode` it as one.
  static const _activityPayloadPrefix = 'activity:';

  static Future<void> initialize({required GlobalKey<NavigatorState> navigatorKey}) async {
    _navigatorKey = navigatorKey;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: onBackgroundTap,
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      'Alarms & Reminders',
      description: 'KinRing group alarms and reminders',
      importance: Importance.max,
      playSound: true,
    );
    const activityChannel = AndroidNotificationChannel(
      _activityChannelId,
      'Group Activity',
      description: 'Members joining, new events, profile updates',
      importance: Importance.defaultImportance,
    );
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
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
  /// its sound/vibration (real device volume/vibration control isn't
  /// exposed per-notification by Android, so "Volume"/"Vibration" here
  /// are a best-effort on/off derived from the slider being above 0,
  /// not a continuous level).
  static Future<void> showAlarmNotification({
    required int id,
    required String title,
    required String body,
    required String payloadJson,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final soundsOn = prefs.getBool('notif_alarm_sounds') ?? true;
    final volume = prefs.getDouble('notif_volume') ?? 0.8;
    final vibration = prefs.getDouble('notif_vibration') ?? 0.6;

    final details = AndroidNotificationDetails(
      _channelId,
      'Alarms & Reminders',
      channelDescription: 'KinRing group alarms and reminders',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      playSound: soundsOn && volume > 0,
      enableVibration: vibration > 0,
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
      _channelId,
      'Alarms & Reminders',
      channelDescription: 'KinRing group alarms and reminders',
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
    if (!(prefs.getBool('notif_group_activity_updates') ?? false)) return;

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

  static Future<void> dismiss(int id) => _plugin.cancel(id);

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
    final draft = EventDraft.fromJson(jsonDecode(payloadJson) as Map<String, dynamic>);
    EventTrigger.fire(context, draft);
  }
}

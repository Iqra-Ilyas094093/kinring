import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../models/event_draft.dart';
import 'event_trigger.dart';

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
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
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
  static Future<void> showAlarmNotification({
    required int id,
    required String title,
    required String body,
    required String payloadJson,
  }) async {
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
    );
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: details),
      payload: payloadJson,
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
    final draft = EventDraft.fromJson(jsonDecode(payloadJson) as Map<String, dynamic>);
    EventTrigger.fire(context, draft);
  }
}

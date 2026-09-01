import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/alarm_scheduler.dart';
import 'core/services/local_notifications_service.dart';
import 'firebase_options.dart';

/// Shared across the app so services outside the widget tree (the
/// alarm-fired notification tap handler, see
/// `LocalNotificationsService`) can still push a route.
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Phase 4 — must be initialized before any event is created/edited,
  // since `EventsViewModel` schedules alarms inline with its Firestore
  // writes.
  await AlarmScheduler.initialize();
  await LocalNotificationsService.initialize(navigatorKey: navigatorKey);

  runApp(const KinRingApp());

  // Cold start via a tapped alarm notification (app was fully killed) —
  // needs the widget tree attached first, so this runs after `runApp`.
  await LocalNotificationsService.routeIfLaunchedFromNotification();
}

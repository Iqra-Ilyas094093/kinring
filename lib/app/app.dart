import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../main.dart' show navigatorKey;
import '../ui/auth/auth_gate.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/events_viewmodel.dart';
import '../viewmodels/groups_viewmodel.dart';

/// Root widget. This is the only place `MaterialApp` is constructed, and
/// the only place `theme:` is set — every screen inherits it via
/// `Theme.of(context)`, never by building its own `ThemeData`.
///
/// [AuthViewModel], [GroupsViewModel], and [EventsViewModel] are each
/// provided once, here, at the app root — every screen shares the exact
/// same instance (and therefore the same in-flight loading/error state
/// and the same Firestore streams), same pattern as `AuthViewModel`
/// already used. `navigatorKey` is set on `MaterialApp` so a fired alarm
/// notification (tapped outside any screen's `BuildContext`) can still
/// push a route — see `LocalNotificationsService`.
class KinRingApp extends StatelessWidget {
  const KinRingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => GroupsViewModel()),
        ChangeNotifierProvider(create: (_) => EventsViewModel()),
      ],
      child: MaterialApp(
        title: 'KinRing',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}

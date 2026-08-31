import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../ui/auth/auth_gate.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Root widget. This is the only place `MaterialApp` is constructed, and
/// the only place `theme:` is set — every screen inherits it via
/// `Theme.of(context)`, never by building its own `ThemeData`.
///
/// [AuthViewModel] is provided once, here, at the app root — every auth
/// screen and [AuthGate] share the exact same instance (and therefore the
/// same in-flight loading/error state and the same Firebase session
/// stream).
class KinRingApp extends StatelessWidget {
  const KinRingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: MaterialApp(
        title: 'KinRing',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}

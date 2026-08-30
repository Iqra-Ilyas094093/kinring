import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../ui/splash/splash_screen.dart';

/// Root widget. This is the only place `MaterialApp` is constructed, and
/// the only place `theme:` is set — every screen inherits it via
/// `Theme.of(context)`, never by building its own `ThemeData`.
class KinRingApp extends StatelessWidget {
  const KinRingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KinRing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}

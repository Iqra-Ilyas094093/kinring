import 'package:flutter/material.dart';

/// Central color palette for KinRing — Light theme only (MVP).
///
/// Rule: no screen or widget should ever write a hex color directly.
/// Every color used in the UI must come from here (or from
/// `Theme.of(context).colorScheme` / `AppTheme`, which is built from this
/// file). If a new color is needed, add it here first.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF492355); // Purple
  static const Color secondary = Color(0xFF4C5E9D); // Indigo
  static const Color headingPurple = Color(0xFF7C518B); // Lighter purple
  static const Color background = Color(0xFFF9F5F4);
  static const Color border = Color(0xFFE7E3EC);

  // State
  static const Color error = Color(0xFFD7263D);
  static const Color warning = Color(0xFFE0A23E);
  static const Color info = Color(0xFF4C5E9D);
  static const Color success = Color(0xFF3E9D5A);

  // Dark shades — text / high-contrast elements on light theme
  static const Color dark1 = Color(0xFF1F1937);
  static const Color dark2 = Color(0xFF675998);

  // Light shades — subtle fills / backgrounds
  static const Color light1 = Color(0xFFF3F1F7);
  static const Color light2 = Color(0xFFECE9F2);

  // Accent
  static const Color accentGold = Color(0xFFAB864F);

  // Status badges (Live Group Status Screen)
  static const Color statusCleared = success;
  static const Color statusRinging = primary;
  static const Color statusSnoozed = warning;
  static const Color statusPendingBg = light2;
  static const Color statusPendingText = dark2;

  // Common neutrals derived from the palette (kept here, not inline)
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Colors.transparent;
}

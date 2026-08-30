import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Central typography for KinRing.
///
/// Font theory:
/// - **Sora** (headings) — geometric, confident, slightly rounded terminals.
///   Used for anything that announces or titles a screen/section: h1-h3,
///   button labels, and the app name/logo wordmark. It carries the brand's
///   "call to action" energy (the ring/bell concept).
/// - **Poppins** (body) — geometric sans but calmer and more neutral at
///   small sizes than Sora, so long-form copy, form labels, and helper
///   text stay easy to read. Pairing two geometric families keeps the
///   whole app visually consistent (no serif/sans clash) while still
///   giving headings a distinct, heavier presence than body copy.
///
/// Never call `GoogleFonts.sora(...)` or `GoogleFonts.poppins(...)` directly
/// in a screen/widget — use `Theme.of(context).textTheme.<style>` instead,
/// which resolves to this file's definitions.
class AppTextTheme {
  AppTextTheme._();

  static TextTheme get textTheme => TextTheme(
        // Headings — Sora
        displayLarge: GoogleFonts.sora(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.dark1,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.sora(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.dark1,
          height: 1.2,
        ),
        headlineLarge: GoogleFonts.sora(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.dark1,
          height: 1.25,
        ),
        headlineMedium: GoogleFonts.sora(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.dark1,
          height: 1.25,
        ),
        headlineSmall: GoogleFonts.sora(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.headingPurple,
          height: 1.3,
        ),
        titleLarge: GoogleFonts.sora(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.dark1,
        ),

        // Body — Poppins
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.dark1,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.dark1,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.dark2,
          height: 1.4,
        ),

        // Labels — Poppins (buttons, chips, badges)
        labelLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.dark2,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.dark2,
        ),
      );
}

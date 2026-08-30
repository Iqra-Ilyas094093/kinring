import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Small auto-dismiss message at the bottom of the screen. Used for
/// "Task Failed", "Invite Code Copied", "Event Created" and similar.
///
/// Usage: `AppToast.show(context, 'Invite code copied')`.
class AppToast {
  AppToast._();

  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.neutral,
  }) {
    final color = switch (type) {
      AppToastType.success => AppColors.success,
      AppToastType.error => AppColors.error,
      AppToastType.neutral => AppColors.dark1,
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
  }
}

enum AppToastType { success, error, neutral }

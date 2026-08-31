import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/list_row.dart';
import 'about_help_screen.dart';
import 'account_settings_screen.dart';
import 'accessibility_settings_screen.dart';
import 'notification_settings_screen.dart';

/// Settings tab (product doc 5.5.3 + 5.10). Entry point into the four
/// sub-screens; owns nothing but navigation + logout.
///
/// TODO: wire profile photo/name/email + logout to a UserViewModel once
/// one exists (mirrors AuthViewModel pattern used in the auth flow).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _demoName = 'Alex Rivera';
  static const _demoEmail = 'alex.rivera@example.com';

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Log Out',
      isDestructive: true,
    );
    if (confirmed) {
      // TODO: call AuthViewModel.signOut() — AuthGate will route to
      // Welcome Screen automatically once the session clears.
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          children: [
            Text('Settings', style: textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.lg),
            InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    const AppAvatar(name: _demoName, size: 56),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_demoName, style: textTheme.titleLarge),
                          Text(_demoEmail, style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.dark2),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListRow(
              label: 'Account Settings',
              leading: const Icon(Icons.person_outline, color: AppColors.dark1),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
              ),
            ),
            ListRow(
              label: 'Notification Settings',
              leading: const Icon(Icons.notifications_outlined, color: AppColors.dark1),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
              ),
            ),
            ListRow(
              label: 'Accessibility Settings',
              leading: const Icon(Icons.accessibility_new_outlined, color: AppColors.dark1),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccessibilitySettingsScreen()),
              ),
            ),
            ListRow(
              label: 'About & Help',
              leading: const Icon(Icons.help_outline, color: AppColors.dark1),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutHelpScreen()),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListRow(
              label: 'Log Out',
              leading: const Icon(Icons.logout, color: AppColors.error),
              isDestructive: true,
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }
}

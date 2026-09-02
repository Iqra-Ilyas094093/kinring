import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../viewmodels/auth_viewmodel.dart';
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
/// Live data: [AuthViewModel.currentUser] for name/email/photo.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Log Out',
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      // AuthGate listens to the Firebase session stream and routes back
      // to Welcome Screen automatically once this clears — no manual
      // navigation needed here.
      await context.read<AuthViewModel>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = context.watch<AuthViewModel>().currentUser;
    final name = (user?.displayName?.trim().isNotEmpty ?? false) ? user!.displayName!.trim() : 'Member';
    final email = user?.email ?? '';

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
                    AppAvatar(name: name, imageUrl: user?.photoURL, size: 56),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: textTheme.titleLarge),
                          Text(email, style: textTheme.bodySmall),
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

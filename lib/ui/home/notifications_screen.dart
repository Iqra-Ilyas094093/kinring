import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/notification_item.dart';
import '../../viewmodels/notifications_viewmodel.dart';
import '../../widgets/common/empty_state.dart';

/// Notifications screen. Reached from the Home tab's notification bell.
/// Not separately specced in Part 5 (the doc only mentions the bell icon
/// itself) — this is the destination that bell now opens into.
///
/// Phase 5 — was `_demoNotifications`, now streams
/// `notifications/{uid}/items` via [NotificationsViewModel]. The
/// `NotificationKind` enum lives on [NotificationItem] now (was
/// duplicated locally here) so the Firestore model and this screen can't
/// drift out of sync.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  ({IconData icon, Color color}) _styleFor(NotificationKind kind) => switch (kind) {
        NotificationKind.cleared => (icon: Icons.check_circle_rounded, color: AppColors.success),
        NotificationKind.snoozed => (icon: Icons.snooze_rounded, color: AppColors.warning),
        NotificationKind.ringNow => (icon: Icons.campaign_rounded, color: AppColors.error),
        NotificationKind.reminderConfirmed => (icon: Icons.notifications_rounded, color: AppColors.secondary),
        NotificationKind.groupActivity => (icon: Icons.groups_rounded, color: AppColors.primary),
        NotificationKind.eventCreated => (icon: Icons.alarm_add_rounded, color: AppColors.secondary),
        NotificationKind.profileUpdated => (icon: Icons.person_rounded, color: AppColors.primary),
      };

  String _relativeTime(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final viewModel = context.read<NotificationsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: StreamBuilder<List<NotificationItem>>(
          stream: viewModel.listenNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data ?? const <NotificationItem>[];
            if (items.isEmpty) {
              return const Center(
                child: EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No notifications yet',
                  subtitle: "You'll see group activity here.",
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final item = items[i];
                final style = _styleFor(item.kind);
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.light1,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        alignment: Alignment.center,
                        child: Icon(style.icon, color: style.color, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: textTheme.bodyLarge),
                            const SizedBox(height: 2),
                            Text(_relativeTime(item.ts), style: textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

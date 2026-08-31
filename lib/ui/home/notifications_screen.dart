import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/common/empty_state.dart';

enum NotificationKind { cleared, snoozed, ringNow, reminder, groupActivity }

/// Notifications screen. Reached from the Home tab's notification bell.
/// Not separately specced in Part 5 (the doc only mentions the bell icon
/// itself) — this is the destination that bell now opens into.
///
/// TODO: replace `_demoNotifications` with a NotificationsViewModel fed
/// by Firestore (group activity) and FCM (Ring Now / event-fired pushes).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _demoNotifications = [
    (
      kind: NotificationKind.cleared,
      title: 'Sam Chen cleared "Exam Squad Study"',
      subtitle: 'Exam Squad · 2 min ago',
    ),
    (
      kind: NotificationKind.snoozed,
      title: 'Jon Kim snoozed "Exam Squad Study"',
      subtitle: 'Exam Squad · 4 min ago',
    ),
    (
      kind: NotificationKind.ringNow,
      title: 'Admin rang the group instantly',
      subtitle: 'Design Team · 1 hr ago',
    ),
    (
      kind: NotificationKind.reminder,
      title: '"Daily Standup" reminder confirmed by all',
      subtitle: 'Design Team · Yesterday',
    ),
    (
      kind: NotificationKind.groupActivity,
      title: 'Priya Nair joined Gym Crew',
      subtitle: 'Gym Crew · 2 days ago',
    ),
  ];

  ({IconData icon, Color color}) _styleFor(NotificationKind kind) => switch (kind) {
        NotificationKind.cleared => (icon: Icons.check_circle_rounded, color: AppColors.success),
        NotificationKind.snoozed => (icon: Icons.snooze_rounded, color: AppColors.warning),
        NotificationKind.ringNow => (icon: Icons.campaign_rounded, color: AppColors.error),
        NotificationKind.reminder => (icon: Icons.notifications_rounded, color: AppColors.secondary),
        NotificationKind.groupActivity => (icon: Icons.groups_rounded, color: AppColors.primary),
      };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: _demoNotifications.isEmpty
            ? const Center(
                child: EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No notifications yet',
                  subtitle: "You'll see group activity here.",
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _demoNotifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final item = _demoNotifications[i];
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
                              Text(item.subtitle, style: textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

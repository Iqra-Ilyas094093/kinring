import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum EventKind { alarm, reminder }

/// Title, group name, time, and a type icon (alarm/reminder). Used on
/// Home ("Upcoming" list), Group Details ("Upcoming Events"), and Event
/// History.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.title,
    required this.groupName,
    required this.timeLabel,
    required this.kind,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String groupName;
  final String timeLabel;
  final EventKind kind;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final icon = kind == EventKind.alarm ? Icons.alarm_rounded : Icons.notifications_rounded;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.light1,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(groupName, style: textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeLabel, style: textTheme.labelMedium),
                if (trailing != null) ...[
                  const SizedBox(height: 4),
                  trailing!,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

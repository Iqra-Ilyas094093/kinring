import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/event_card.dart';

/// Event History Screen (product doc 5.9.3). Reverse-chronological list
/// of past events with a quick summary; tapping one shows per-member
/// clear times.
///
/// TODO: replace `_demoHistory` with an EventsViewModel query (past
/// events for this group, newest first).
class EventHistoryScreen extends StatelessWidget {
  const EventHistoryScreen({super.key, required this.groupName});

  final String groupName;

  static const _demoHistory = [
    (
      title: 'Study Session',
      date: 'Aug 29, 2026',
      kind: EventKind.alarm,
      summary: '3/4 cleared on time',
      clearTimes: [
        (name: 'Alex Rivera', time: '6:00 AM'),
        (name: 'Sam Chen', time: '6:02 AM'),
        (name: 'Priya Nair', time: '6:04 AM'),
        (name: 'Jon Kim', time: '6:19 AM (after 1 snooze)'),
      ],
    ),
    (
      title: 'Daily Standup',
      date: 'Aug 28, 2026',
      kind: EventKind.reminder,
      summary: '4/4 cleared on time',
      clearTimes: [
        (name: 'Alex Rivera', time: '9:00 AM'),
        (name: 'Sam Chen', time: '9:01 AM'),
        (name: 'Priya Nair', time: '9:00 AM'),
        (name: 'Jon Kim', time: '9:03 AM'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: _demoHistory.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final item = _demoHistory[i];
            return InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              onTap: () => _showClearTimes(context, item.title, item.clearTimes),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.kind == EventKind.alarm ? Icons.alarm_rounded : Icons.notifications_rounded,
                      color: AppColors.dark2,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: textTheme.bodyLarge),
                          Text('$groupName · ${item.date}', style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Text(item.summary, style: textTheme.labelMedium),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showClearTimes(
    BuildContext context,
    String eventTitle,
    List<({String name, String time})> clearTimes,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eventTitle, style: textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.md),
                for (final entry in clearTimes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        AppAvatar(name: entry.name, size: 32),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(entry.name, style: textTheme.bodyLarge)),
                        Text(entry.time, style: textTheme.bodySmall),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

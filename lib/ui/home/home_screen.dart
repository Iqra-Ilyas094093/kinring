import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/common/group_card.dart';
import '../../widgets/common/section_header.dart';
import '../events/create_event_screen.dart';
import '../events/upcoming_event_detail_screen.dart';
import '../groups/group_details_screen.dart';
import 'notifications_screen.dart';

/// Home tab (product doc 5.5.1). Greeting + notification bell, "Upcoming"
/// events across all groups, "Your Groups" horizontal scroll, empty state
/// when there are no events yet, and a FAB into the Create Event flow.
///
/// TODO: replace the demo data below with a HomeViewModel backed by
/// Firestore once the Group/Event flows and their models exist.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _demoName = 'Alex';

  // Demo data — stands in for real events/groups until the backend and
  // Group/Event flows are built.
  static const _demoEvents = [
    (title: 'Exam Squad Study', group: 'Exam Squad', time: '6:00 AM', kind: EventKind.alarm),
    (title: 'Daily Standup', group: 'Design Team', time: '9:00 AM', kind: EventKind.reminder),
  ];

  static const _demoGroups = [
    (name: 'Exam Squad', members: ['Alex', 'Sam', 'Priya', 'Jon'], next: 'Alarm · 6:00 AM'),
    (name: 'Design Team', members: ['Alex', 'Mira'], next: 'Reminder · 9:00 AM'),
    (name: 'Gym Crew', members: ['Alex', 'Dev', 'Lee'], next: null),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasEvents = _demoEvents.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hi, $_demoName', style: textTheme.headlineLarge),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.dark1),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!hasEvents)
              EmptyState(
                icon: Icons.alarm_outlined,
                title: 'No events yet',
                subtitle: 'Create your first alarm to get your group moving together.',
                actionLabel: 'Create your first alarm',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                ),
              )
            else ...[
              const SectionHeader(title: 'Upcoming'),
              const SizedBox(height: AppSpacing.sm),
              for (final event in _demoEvents) ...[
                EventCard(
                  title: event.title,
                  groupName: event.group,
                  timeLabel: event.time,
                  kind: event.kind,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UpcomingEventDetailScreen(
                        draft: EventDraft(
                          groupName: event.group,
                          kind: event.kind,
                          title: event.title,
                          date: DateTime.now(),
                          time: DateTime.now(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Your Groups'),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _demoGroups.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final group = _demoGroups[i];
                  return GroupCard(
                    width: 220,
                    groupName: group.name,
                    memberNames: group.members,
                    nextEventLabel: group.next,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupDetailsScreen(groupName: group.name),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateEventScreen()),
        ),
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}

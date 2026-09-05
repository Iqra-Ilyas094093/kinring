import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/group_event_model.dart';
import '../../models/group_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/events_viewmodel.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../../viewmodels/notifications_viewmodel.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/common/group_card.dart';
import '../../widgets/common/live_events_stream_builder.dart';
import '../../widgets/common/section_header.dart';
import '../events/create_event_screen.dart';
import '../events/upcoming_event_detail_screen.dart';
import '../groups/group_details_screen.dart';
import 'notifications_screen.dart';

/// Home tab (product doc 5.5.1). Greeting + notification bell, "Upcoming"
/// events across all groups, "Your Groups" horizontal scroll, empty state
/// when there are no events yet, and a FAB into the Create Event flow.
///
/// Live data: [EventsViewModel.listenUpcomingEvents] and
/// [GroupsViewModel.listenGroups], both provided at the app root.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayName = context.watch<AuthViewModel>().currentUser?.displayName;
    final greetingName = (displayName == null || displayName.trim().isEmpty)
        ? 'there'
        : displayName.trim().split(' ').first;

    final eventsVm = context.read<EventsViewModel>();
    final groupsVm = context.read<GroupsViewModel>();

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
                Text('Hi, $greetingName', style: textTheme.headlineLarge),
                StreamBuilder<int>(
                  stream: context.read<NotificationsViewModel>().listenUnreadCount(),
                  builder: (context, unreadSnap) {
                    final unread = unreadSnap.data ?? 0;
                    return Badge(
                      label: Text('$unread'),
                      isLabelVisible: unread > 0,
                      child: IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: AppColors.dark1),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            LiveEventsStreamBuilder(
              streamBuilder: eventsVm.listenUpcomingEvents,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Text(
                      'Could not load events: ${snapshot.error}',
                      style: textTheme.bodySmall?.copyWith(color: AppColors.error),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final events = snapshot.data ?? const <GroupEventModel>[];
                if (events.isEmpty) {
                  return EmptyState(
                    icon: Icons.alarm_outlined,
                    title: 'No events yet',
                    subtitle: 'Create your first alarm to get your group moving together.',
                    actionLabel: 'Create your first alarm',
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Upcoming'),
                    const SizedBox(height: AppSpacing.sm),
                    for (final event in events) ...[
                      EventCard(
                        title: event.title,
                        groupName: event.groupName,
                        timeLabel: event.timeUTC.toLocal().toString().substring(11, 16),
                        kind: event.kind,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => UpcomingEventDetailScreen(draft: event.toDraft()),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Your Groups'),
            const SizedBox(height: AppSpacing.sm),
            StreamBuilder<List<GroupModel>>(
              stream: groupsVm.listenGroups(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final groups = snapshot.data ?? const <GroupModel>[];
                if (groups.isEmpty) {
                  return const Text("You're not in any groups yet.");
                }
                return SizedBox(
                  height: 132,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final group = groups[i];
                      return StreamBuilder<List<GroupMemberModel>>(
                        stream: groupsVm.listenMembers(group.id),
                        builder: (context, memberSnap) {
                          final memberNames = (memberSnap.data ?? const <GroupMemberModel>[])
                              .map((m) => m.displayName ?? 'Member')
                              .toList();
                          final memberPhotoUrls = (memberSnap.data ?? const <GroupMemberModel>[])
                              .map((m) => m.photoUrl)
                              .toList();
                          return GroupCard(
                            width: 220,
                            groupName: group.name,
                            photoUrl: group.photoUrl,
                            memberNames: memberNames.isEmpty
                                ? List.filled(group.memberCount, 'Member')
                                : memberNames,
                            memberPhotoUrls: memberNames.isEmpty ? null : memberPhotoUrls,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GroupDetailsScreen(
                                  groupId: group.id,
                                  groupName: group.name,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
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

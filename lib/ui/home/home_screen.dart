import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
import '../../models/event_model.dart';
import '../../models/group_model.dart';
import '../../viewmodels/events_viewmodel.dart';
import '../../viewmodels/groups_viewmodel.dart';
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
/// Both sections are live: "Your Groups" via
/// [GroupsViewModel.listenGroups] (Phase 2), "Upcoming" via
/// [EventsViewModel.listenUpcomingEventsAcrossGroups] (Phase 3) — a
/// newly created event or a newly joined group appears without a
/// refresh.
///
/// TODO(Phase 10): greeting name is still a placeholder — wire to
/// `users/{uid}.name` alongside Account Settings.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _demoName = 'Alex';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final groupsVm = context.read<GroupsViewModel>();
    final eventsVm = context.read<EventsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<Group>>(
          stream: groupsVm.listenGroups(),
          builder: (context, groupsSnap) {
            final groups = groupsSnap.data ?? const <Group>[];
            final groupNameById = {for (final g in groups) g.id: g.name};

            return ListView(
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
                StreamBuilder<List<FirestoreEvent>>(
                  stream: eventsVm.listenUpcomingEventsAcrossGroups(groups.map((g) => g.id).toList()),
                  builder: (context, eventsSnap) {
                    final events = eventsSnap.data ?? const <FirestoreEvent>[];
                    final stillLoading =
                        groupsSnap.connectionState == ConnectionState.waiting ||
                        (eventsSnap.connectionState == ConnectionState.waiting && events.isEmpty);

                    if (stillLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      );
                    }

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
                        for (final event in events)
                          Builder(builder: (context) {
                            final groupName = groupNameById[event.groupId] ?? '';
                            final draft = EventDraft.fromFirestore(
                              id: event.id,
                              groupId: event.groupId,
                              groupName: groupName,
                              kind: event.kind,
                              title: event.title,
                              localTime: event.timeUTC.toLocal(),
                              repeatRule: event.repeatRule,
                              customDays: event.customDays.toSet(),
                              snoozeEnabled: event.snoozeEnabled,
                              confirmationPhrase: event.confirmationPhrase,
                              useSimpleTap: event.useSimpleTap,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: EventCard(
                                title: draft.title,
                                groupName: groupName,
                                timeLabel: draft.timeLabel,
                                kind: draft.kind,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => UpcomingEventDetailScreen(draft: draft),
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Your Groups'),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 132,
                  child: groupsSnap.connectionState == ConnectionState.waiting && groups.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : groups.isEmpty
                          ? const Center(child: Text("You're not in any groups yet"))
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: groups.length,
                              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                              itemBuilder: (context, i) {
                                final group = groups[i];
                                return GroupCard(
                                  width: 220,
                                  groupName: group.name,
                                  memberNames: group.memberIds,
                                  photoUrl: group.photoUrl,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          GroupDetailsScreen(groupId: group.id, groupName: group.name),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            );
          },
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

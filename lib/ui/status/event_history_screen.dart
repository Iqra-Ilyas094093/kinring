import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_status_model.dart';
import '../../models/group_event_model.dart';
import '../../viewmodels/event_status_viewmodel.dart';
import '../../viewmodels/events_viewmodel.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/common/status_badge.dart';

/// Event History Screen (product doc 5.9.3). Reverse-chronological list
/// of past events with a per-member clear-time summary.
///
/// Phase 10: [EventsViewModel.listenPastEvents] for the list;
/// [EventStatusViewModel.fetchStatuses] (one-time, not live — history
/// doesn't change) for each card's "X/Y cleared" line and the per-member
/// clear-time dialog on tap.
class EventHistoryScreen extends StatelessWidget {
  const EventHistoryScreen({super.key, required this.groupId, required this.groupName});

  final String groupId;
  final String groupName;

  @override
  Widget build(BuildContext context) {
    final eventsVm = context.read<EventsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        child: StreamBuilder<List<GroupEventModel>>(
          stream: eventsVm.listenPastEvents(groupId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final events = snap.data ?? const <GroupEventModel>[];
            if (events.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No past events yet',
                    subtitle: 'Events show up here once their scheduled time has passed.',
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => _HistoryEventCard(event: events[i], groupName: groupName),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryEventCard extends StatelessWidget {
  const _HistoryEventCard({required this.event, required this.groupName});

  final GroupEventModel event;
  final String groupName;

  @override
  Widget build(BuildContext context) {
    final statusVm = EventStatusViewModel();
    return FutureBuilder<List<EventStatusModel>>(
      future: statusVm.fetchStatuses(groupId: event.groupId, eventId: event.id),
      builder: (context, snap) {
        final statuses = snap.data ?? const <EventStatusModel>[];
        final clearedCount = statuses.where((s) => s.status == EventMemberStatus.cleared).length;
        final totalCount = event.memberIds.length;
        final summary = snap.connectionState == ConnectionState.waiting
            ? 'Loading…'
            : '$clearedCount/$totalCount cleared';

        return EventCard(
          title: event.title.isEmpty ? (event.kind == EventKind.alarm ? 'Alarm' : 'Reminder') : event.title,
          groupName: groupName,
          timeLabel: '${event.timeUTC.toLocal()}'.substring(0, 16),
          kind: event.kind,
          trailing: Text(summary, style: Theme.of(context).textTheme.labelMedium),
          onTap: statuses.isEmpty
              ? null
              : () => _showMemberClearTimes(context, event: event, statuses: statuses),
        );
      },
    );
  }

  void _showMemberClearTimes(
    BuildContext context, {
    required GroupEventModel event,
    required List<EventStatusModel> statuses,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.title.isEmpty ? 'Event' : event.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.md),
              for (final s in statuses)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      StatusBadge(status: s.status),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          s.clearedAt != null ? 'Cleared at ${s.clearedAt!.toLocal()}'.substring(0, 22) : 'Not cleared',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

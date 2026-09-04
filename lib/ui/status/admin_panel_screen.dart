import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/services/event_trigger.dart';
import '../../core/services/ring_now_service.dart';
import '../../models/event_draft.dart';
import '../../models/group_event_model.dart';
import '../../models/group_model.dart';
import '../../viewmodels/events_viewmodel.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/common/list_row.dart';
import '../../widgets/common/live_events_stream_builder.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/feedback/app_toast.dart';
import '../groups/group_settings_screen.dart';
import '../events/edit_event_screen.dart';
import 'event_history_screen.dart';

/// Admin Panel Screen (product doc 5.9.2). The prominent "Ring Now"
/// broadcast, a quick-edit list of past/upcoming events, and a shortcut
/// into Group Settings.
///
/// Live data: [EventsViewModel.listenGroupEvents] for the events list.
/// "Ring Now" (Phase 7): [RingNowService] POSTs to the Cloudflare Worker,
/// which verifies admin membership server-side and pushes the broadcast
/// to every member's device(s), bypassing silent/DND. The local
/// [EventTrigger.fire] call alongside it is just for the tapping admin's
/// own screen — instant feedback without waiting on the network
/// round-trip; the push is what reaches everyone else.
class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key, required this.groupId, required this.groupName});

  final String groupId;
  final String groupName;

  Future<void> _ringNow(BuildContext context, List<String> memberIds) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Ring Now',
      message: 'This will instantly alert all ${memberIds.length} members. Continue?',
      confirmLabel: 'Ring Now',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final eventsVm = context.read<EventsViewModel>();
    // Phase 8 fix: a real event doc so this broadcast gets the same
    // statuses tracking a scheduled event does — previously Ring Now
    // had no backing doc, so markCleared always no-opped and Live
    // Status showed everyone "Pending" forever, even after clearing.
    final eventId = await eventsVm.createBroadcastEvent(groupId: groupId, memberIds: memberIds);

    if (!context.mounted) return;
    EventTrigger.fire(
      context,
      EventDraft(
        groupId: groupId,
        groupName: groupName,
        eventId: eventId,
        title: 'Ring Now Broadcast',
        kind: EventKind.alarm,
        snoozeEnabled: false,
      ),
    );

    try {
      await RingNowService.ringNow(groupId, eventId: eventId);
    } catch (e) {
      if (context.mounted) {
        AppToast.show(context, 'Could not reach other members: $e', type: AppToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final groupsVm = context.read<GroupsViewModel>();
    final eventsVm = context.read<EventsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Admin Panel — $groupName')),
      body: SafeArea(
        child: StreamBuilder<GroupModel?>(
          stream: groupsVm.listenGroup(groupId),
          builder: (context, groupSnap) {
            final memberIds = groupSnap.data?.memberIds ?? const <String>[];
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: memberIds.isEmpty ? null : () => _ringNow(context, memberIds),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    icon: const Icon(Icons.campaign_rounded, color: AppColors.white),
                    label: Text(
                      'Ring Now',
                      style: textTheme.titleLarge?.copyWith(color: AppColors.white),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Instantly broadcasts to every member, bypassing silent mode.',
                  style: textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(
                  title: 'Events',
                  trailing: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventHistoryScreen(groupId: groupId, groupName: groupName),
                      ),
                    ),
                    child: const Text('View History'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                LiveEventsStreamBuilder(
                  streamBuilder: () => eventsVm.listenGroupEvents(groupId),
                  builder: (context, eventSnap) {
                    if (eventSnap.hasError) {
                      return Text('Could not load events: ${eventSnap.error}', style: textTheme.bodySmall?.copyWith(color: AppColors.error));
                    }
                    final events = eventSnap.data ?? const <GroupEventModel>[];
                    if (events.isEmpty) {
                      return Text('No upcoming events yet.', style: textTheme.bodySmall);
                    }
                    return Column(
                      children: [
                        for (final event in events) ...[
                          EventCard(
                            title: event.title,
                            groupName: groupName,
                            timeLabel: event.timeUTC.toLocal().toString().substring(11, 16),
                            kind: event.kind,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EditEventScreen(draft: event.toDraft()),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                ListRow(
                  label: 'Group Settings',
                  leading: const Icon(Icons.settings_outlined, color: AppColors.dark1),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GroupSettingsScreen(groupId: groupId, groupName: groupName),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

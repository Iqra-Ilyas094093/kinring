import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/group_event_model.dart';
import '../../models/group_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/events_viewmodel.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/common/list_row.dart';
import '../../widgets/common/live_events_stream_builder.dart';
import '../../widgets/common/section_header.dart';
import '../events/upcoming_event_detail_screen.dart';
import '../status/admin_panel_screen.dart';
import 'group_settings_screen.dart';
import 'invite_members_screen.dart';

/// Group Details screen (product doc 5.6.3). Member list (with admin
/// badge), upcoming events for this group, an admin-only Admin Panel
/// entry point, and Invite Members.
///
/// Live data: [GroupsViewModel.listenMembers]/[listenGroup] and
/// [EventsViewModel.listenGroupEvents], scoped by [groupId]. [groupName]
/// is only a cached title shown before the live group doc loads.
class GroupDetailsScreen extends StatelessWidget {
  const GroupDetailsScreen({super.key, required this.groupId, required this.groupName});

  final String groupId;
  final String groupName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final groupsVm = context.read<GroupsViewModel>();
    final eventsVm = context.read<EventsViewModel>();
    final myUid = context.read<AuthViewModel>().currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: StreamBuilder<GroupModel?>(
          stream: groupsVm.listenGroup(groupId),
          builder: (context, snap) => Text(snap.data?.name ?? groupName),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.dark1),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupSettingsScreen(groupId: groupId, groupName: groupName),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<GroupMemberModel>>(
          stream: groupsVm.listenMembers(groupId),
          builder: (context, memberSnap) {
            if (memberSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final members = memberSnap.data ?? const <GroupMemberModel>[];
            final isAdmin = members.any((m) => m.uid == myUid && m.isAdmin);

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                SectionHeader(title: 'Members (${members.length})'),
                const SizedBox(height: AppSpacing.sm),
                for (final member in members)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        AppAvatar(name: member.displayName ?? 'Member', imageUrl: member.photoUrl, size: 40),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(member.displayName ?? 'Member', style: textTheme.bodyLarge),
                        ),
                        if (member.isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.light2,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                            ),
                            child: Text('Admin', style: textTheme.labelSmall),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(title: 'Upcoming Events'),
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
                if (isAdmin) ...[
                  const SizedBox(height: AppSpacing.md),
                  ListRow(
                    label: 'Admin Panel',
                    leading: const Icon(Icons.shield_outlined, color: AppColors.dark1),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminPanelScreen(groupId: groupId, groupName: groupName),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                StreamBuilder<GroupModel?>(
                  stream: groupsVm.listenGroup(groupId),
                  builder: (context, groupSnap) {
                    final inviteCode = groupSnap.data?.inviteCode ?? '';
                    return PrimaryButton(
                      label: 'Invite Members',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InviteMembersScreen(
                            groupName: groupSnap.data?.name ?? groupName,
                            inviteCode: inviteCode,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

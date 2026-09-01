import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
import '../../models/event_model.dart';
import '../../models/group_model.dart';
import '../../viewmodels/events_viewmodel.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/common/list_row.dart';
import '../../widgets/common/section_header.dart';
import '../events/upcoming_event_detail_screen.dart';
import '../status/admin_panel_screen.dart';
import 'group_settings_screen.dart';
import 'invite_members_screen.dart';

/// Group Details screen (product doc 5.6.3). Member list (with admin
/// badge), upcoming events for this group, an admin-only Admin Panel
/// entry point, and Invite Members.
///
/// Members + role (via [GroupsViewModel]) and Upcoming Events (via
/// [EventsViewModel], Phase 3) are all live Firestore streams — a
/// promotion, a new joiner, or a newly created event show up here
/// without a refresh. `groupName` is kept as a fallback title for the
/// brief window before the live group doc loads.
class GroupDetailsScreen extends StatelessWidget {
  const GroupDetailsScreen({super.key, required this.groupId, required this.groupName});

  final String groupId;
  final String groupName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final vm = context.read<GroupsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: StreamBuilder<Group?>(
          stream: vm.watchGroup(groupId),
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
        child: StreamBuilder<GroupRole?>(
          stream: vm.watchMyRole(groupId),
          builder: (context, roleSnap) {
            final isAdmin = roleSnap.data == GroupRole.admin;

            return StreamBuilder<List<GroupMemberProfile>>(
              stream: vm.listenMembersWithProfiles(groupId),
              builder: (context, memberSnap) {
                final members = memberSnap.data ?? const <GroupMemberProfile>[];

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    SectionHeader(title: 'Members (${members.length})'),
                    const SizedBox(height: AppSpacing.sm),
                    if (memberSnap.connectionState == ConnectionState.waiting && members.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      ),
                    for (final profile in members)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          children: [
                            AppAvatar(name: profile.displayName, imageUrl: profile.photoUrl, size: 40),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: Text(profile.displayName, style: textTheme.bodyLarge)),
                            if (profile.isAdmin)
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
                    StreamBuilder<List<FirestoreEvent>>(
                      stream: context.read<EventsViewModel>().listenUpcomingEventsForGroup(groupId),
                      builder: (context, eventSnap) {
                        final events = eventSnap.data ?? const <FirestoreEvent>[];
                        if (eventSnap.connectionState == ConnectionState.waiting && events.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: LinearProgressIndicator(color: AppColors.primary),
                          );
                        }
                        if (events.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Text('No upcoming events yet.', style: textTheme.bodyMedium),
                          );
                        }
                        return Column(
                          children: [
                            for (final event in events) ...[
                              Builder(builder: (context) {
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
                          MaterialPageRoute(builder: (_) => AdminPanelScreen(groupId: groupId, groupName: groupName)),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: 'Invite Members',
                      onPressed: () async {
                        final group = await vm.watchGroup(groupId).first;
                        if (group == null || !context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => InviteMembersScreen(
                              groupId: group.id,
                              groupName: group.name,
                              inviteCode: group.inviteCode,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

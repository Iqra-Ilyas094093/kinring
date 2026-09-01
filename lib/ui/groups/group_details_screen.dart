import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
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
/// TODO: replace demo data + `_isAdmin` with a GroupsViewModel lookup.
class GroupDetailsScreen extends StatelessWidget {
  const GroupDetailsScreen({super.key, required this.groupName});

  final String groupName;

  static const _isAdmin = true;
  static const _demoMembers = [
    (name: 'Alex Rivera', isAdmin: true),
    (name: 'Sam Chen', isAdmin: false),
    (name: 'Priya Nair', isAdmin: false),
    (name: 'Jon Kim', isAdmin: false),
  ];
  static const _demoEvents = [
    (title: 'Study Session', time: '6:00 AM', kind: EventKind.alarm),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(groupName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.dark1),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupSettingsScreen(groupName: groupName),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SectionHeader(title: 'Members (${_demoMembers.length})'),
            const SizedBox(height: AppSpacing.sm),
            for (final member in _demoMembers)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    AppAvatar(name: member.name, size: 40),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(member.name, style: textTheme.bodyLarge)),
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
            for (final event in _demoEvents) ...[
              EventCard(
                title: event.title,
                groupName: groupName,
                timeLabel: event.time,
                kind: event.kind,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UpcomingEventDetailScreen(
                      draft: EventDraft(
                        groupName: groupName,
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
            if (_isAdmin) ...[
              const SizedBox(height: AppSpacing.md),
              ListRow(
                label: 'Admin Panel',
                leading: const Icon(Icons.shield_outlined, color: AppColors.dark1),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AdminPanelScreen(groupName: groupName)),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Invite Members',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InviteMembersScreen(
                    groupName: groupName,
                    inviteCode: 'KR-DEMO1',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

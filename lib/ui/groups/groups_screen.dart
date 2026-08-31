import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/group_card.dart';
import 'create_group_screen.dart';
import 'group_details_screen.dart';
import 'join_group_screen.dart';

/// Groups tab (product doc 5.5.2). List of the user's groups, or an
/// empty state with Create/Join actions.
///
/// TODO: replace demo data with a GroupsViewModel backed by Firestore.
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  static const _demoGroups = [
    (name: 'Exam Squad', members: ['Alex', 'Sam', 'Priya', 'Jon'], next: 'Alarm · 6:00 AM'),
    (name: 'Design Team', members: ['Alex', 'Mira'], next: 'Reminder · 9:00 AM'),
    (name: 'Gym Crew', members: ['Alex', 'Dev', 'Lee'], next: null),
  ];

  void _openCreate(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
      );

  void _openJoin(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasGroups = _demoGroups.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Groups', style: textTheme.headlineLarge),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search, color: AppColors.dark1),
                        onPressed: () {
                          // TODO: group search once GroupsViewModel exists.
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: AppColors.dark1),
                        onPressed: () => _showCreateOrJoinSheet(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: hasGroups
                  ? ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: _demoGroups.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final group = _demoGroups[i];
                        return GroupCard(
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
                    )
                  : Center(
                      child: EmptyState(
                        icon: Icons.groups_outlined,
                        title: "You're not in any groups yet",
                        subtitle: 'Create a group or join one with an invite code.',
                        actionLabel: 'Create a Group',
                        onAction: () => _openCreate(context),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateOrJoinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                title: const Text('Create Group'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openCreate(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add_outlined, color: AppColors.primary),
                title: const Text('Join Group'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openJoin(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

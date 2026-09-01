import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/feedback/app_toast.dart';

/// Manage Members screen. Reached from Group Settings' "Manage Members"
/// row (product doc 5.6.5). Lets the admin promote a member to admin or
/// remove them from the group (doc's "Confirm Remove Member" dialog,
/// Part 7 #3).
///
/// TODO: replace `_members` demo list with a GroupsViewModel query;
/// promote/remove should call GroupsViewModel.setAdmin(...) /
/// removeMember(...) instead of only updating local state.
class ManageMembersScreen extends StatefulWidget {
  const ManageMembersScreen({super.key, required this.groupName});

  final String groupName;

  @override
  State<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends State<ManageMembersScreen> {
  static const _isAdmin = true; // TODO: from GroupsViewModel / current user.

  final List<({String name, bool isAdmin})> _members = [
    (name: 'Alex Rivera', isAdmin: true),
    (name: 'Sam Chen', isAdmin: false),
    (name: 'Priya Nair', isAdmin: false),
    (name: 'Jon Kim', isAdmin: false),
  ];

  void _promote(int index) {
    final member = _members[index];
    setState(() => _members[index] = (name: member.name, isAdmin: true));
    // TODO: call GroupsViewModel.setAdmin(member.name, true).
    AppToast.show(context, '${member.name} is now an admin', type: AppToastType.success);
  }

  Future<void> _remove(int index) async {
    final member = _members[index];
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Remove Member',
      message: 'Remove ${member.name} from group?',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (confirmed && mounted) {
      setState(() => _members.removeAt(index));
      // TODO: call GroupsViewModel.removeMember(member.name).
      AppToast.show(context, '${member.name} removed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Manage Members — ${widget.groupName}')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: _members.length,
          separatorBuilder: (_, __) => const Divider(color: AppColors.border),
          itemBuilder: (context, i) {
            final member = _members[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  AppAvatar(name: member.name, size: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.name, style: textTheme.bodyLarge),
                        if (member.isAdmin)
                          Text('Admin', style: textTheme.bodySmall?.copyWith(color: AppColors.headingPurple)),
                      ],
                    ),
                  ),
                  if (_isAdmin)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.dark2),
                      onSelected: (action) {
                        if (action == 'promote') _promote(i);
                        if (action == 'remove') _remove(i);
                      },
                      itemBuilder: (context) => [
                        if (!member.isAdmin)
                          const PopupMenuItem(value: 'promote', child: Text('Promote to Admin')),
                        PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

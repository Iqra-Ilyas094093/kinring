import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/group_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/feedback/app_toast.dart';

/// Manage Members screen. Reached from Group Settings' "Manage Members"
/// row (product doc 5.6.5). Lets the admin promote a member to admin or
/// remove them from the group (doc's "Confirm Remove Member" dialog,
/// Part 7 #3).
///
/// Live data: [GroupsViewModel.listenMembers]/[promoteMember]/[removeMember].
class ManageMembersScreen extends StatelessWidget {
  const ManageMembersScreen({super.key, required this.groupId, required this.groupName});

  final String groupId;
  final String groupName;

  Future<void> _promote(BuildContext context, GroupsViewModel vm, GroupMemberModel member) async {
    await vm.promoteMember(groupId, member.uid);
    if (context.mounted) {
      AppToast.show(context, '${member.displayName ?? 'Member'} is now an admin', type: AppToastType.success);
    }
  }

  Future<void> _remove(BuildContext context, GroupsViewModel vm, GroupMemberModel member) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Remove Member',
      message: 'Remove ${member.displayName ?? 'this member'} from group?',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (confirmed) {
      await vm.removeMember(groupId, member.uid);
      if (context.mounted) AppToast.show(context, '${member.displayName ?? 'Member'} removed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final groupsVm = context.read<GroupsViewModel>();
    final myUid = context.read<AuthViewModel>().currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Manage Members — $groupName')),
      body: SafeArea(
        child: StreamBuilder<List<GroupMemberModel>>(
          stream: groupsVm.listenMembers(groupId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final members = snapshot.data ?? const <GroupMemberModel>[];
            final isAdmin = members.any((m) => m.uid == myUid && m.isAdmin);

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: members.length,
              separatorBuilder: (_, __) => const Divider(color: AppColors.border),
              itemBuilder: (context, i) {
                final member = members[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      AppAvatar(name: member.displayName ?? 'Member', imageUrl: member.photoUrl, size: 40),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(member.displayName ?? 'Member', style: textTheme.bodyLarge),
                            if (member.isAdmin)
                              Text(
                                'Admin',
                                style: textTheme.bodySmall?.copyWith(color: AppColors.headingPurple),
                              ),
                          ],
                        ),
                      ),
                      if (isAdmin)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: AppColors.dark2),
                          onSelected: (action) {
                            if (action == 'promote') _promote(context, groupsVm, member);
                            if (action == 'remove') _remove(context, groupsVm, member);
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
            );
          },
        ),
      ),
    );
  }
}

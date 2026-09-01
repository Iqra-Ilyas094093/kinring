import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/group_model.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/feedback/app_toast.dart';

/// Manage Members screen. Reached from Group Settings' "Manage Members"
/// row (product doc 5.6.5). Lets the admin promote a member to admin or
/// remove them from the group (doc's "Confirm Remove Member" dialog,
/// Part 7 #3).
///
/// Member list + own role are both live via [GroupsViewModel] — a
/// promotion/removal from any device updates every open copy of this
/// screen without a refresh.
class ManageMembersScreen extends StatefulWidget {
  const ManageMembersScreen({super.key, required this.groupId, required this.groupName});

  final String groupId;
  final String groupName;

  @override
  State<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends State<ManageMembersScreen> {
  Future<void> _promote(GroupMemberProfile profile) async {
    await context.read<GroupsViewModel>().promoteMember(widget.groupId, profile.member.uid);
    if (!mounted) return;
    AppToast.show(context, '${profile.displayName} is now an admin', type: AppToastType.success);
  }

  Future<void> _remove(GroupMemberProfile profile) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Remove Member',
      message: 'Remove ${profile.displayName} from group?',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (confirmed && mounted) {
      await context.read<GroupsViewModel>().removeMember(widget.groupId, profile.member.uid);
      if (!mounted) return;
      AppToast.show(context, '${profile.displayName} removed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final vm = context.read<GroupsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Manage Members — ${widget.groupName}')),
      body: SafeArea(
        child: StreamBuilder<GroupRole?>(
          stream: vm.watchMyRole(widget.groupId),
          builder: (context, roleSnap) {
            final isAdmin = roleSnap.data == GroupRole.admin;

            return StreamBuilder<List<GroupMemberProfile>>(
              stream: vm.listenMembersWithProfiles(widget.groupId),
              builder: (context, snap) {
                final members = snap.data ?? const <GroupMemberProfile>[];
                if (snap.connectionState == ConnectionState.waiting && members.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.border),
                  itemBuilder: (context, i) {
                    final profile = members[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          AppAvatar(name: profile.displayName, imageUrl: profile.photoUrl, size: 40),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(profile.displayName, style: textTheme.bodyLarge),
                                if (profile.isAdmin)
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
                                if (action == 'promote') _promote(profile);
                                if (action == 'remove') _remove(profile);
                              },
                              itemBuilder: (context) => [
                                if (!profile.isAdmin)
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
            );
          },
        ),
      ),
    );
  }
}

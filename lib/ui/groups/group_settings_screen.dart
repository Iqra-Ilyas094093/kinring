import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/group_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/list_row.dart';
import '../../widgets/feedback/app_toast.dart';
import '../../widgets/inputs/app_text_field.dart';
import 'manage_members_screen.dart';

/// Group Settings screen (product doc 5.6.5). Editable group name/photo,
/// Manage Members, Leave Group, and admin-only Delete Group.
///
/// Live data: [GroupsViewModel.listenGroup]/[listenMembers] for the
/// current name and admin check; [renameGroup]/[leaveGroup]/[deleteGroup]
/// for the actions.
class GroupSettingsScreen extends StatefulWidget {
  const GroupSettingsScreen({super.key, required this.groupId, required this.groupName});

  final String groupId;
  final String groupName;

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  late final _nameController = TextEditingController(text: widget.groupName);
  bool _nameEdited = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _leaveGroup() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Leave Group',
      message: 'Are you sure you want to leave ${widget.groupName}?',
      confirmLabel: 'Leave',
      isDestructive: true,
    );
    if (confirmed && mounted) {
      await context.read<GroupsViewModel>().leaveGroup(widget.groupId);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Group',
      message: 'This permanently deletes ${widget.groupName} and all its events for every member.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed && mounted) {
      await context.read<GroupsViewModel>().deleteGroup(widget.groupId);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsVm = context.read<GroupsViewModel>();
    final myUid = context.read<AuthViewModel>().currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Group Settings')),
      body: SafeArea(
        child: StreamBuilder<List<GroupMemberModel>>(
          stream: groupsVm.listenMembers(widget.groupId),
          builder: (context, memberSnap) {
            final members = memberSnap.data ?? const <GroupMemberModel>[];
            final isAdmin = members.any((m) => m.uid == myUid && m.isAdmin);

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Center(child: AppAvatar(name: _nameController.text, size: 80)),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Group name',
                  controller: _nameController,
                  onChanged: (_) => setState(() => _nameEdited = true),
                ),
                const SizedBox(height: AppSpacing.lg),
                ListRow(
                  label: 'Manage Members',
                  leading: const Icon(Icons.people_outline, color: AppColors.dark1),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ManageMembersScreen(
                          groupId: widget.groupId,
                          groupName: widget.groupName,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                ListRow(
                  label: 'Leave Group',
                  leading: const Icon(Icons.exit_to_app, color: AppColors.error),
                  isDestructive: true,
                  onTap: _leaveGroup,
                ),
                if (isAdmin)
                  ListRow(
                    label: 'Delete Group',
                    leading: const Icon(Icons.delete_outline, color: AppColors.error),
                    isDestructive: true,
                    onTap: _deleteGroup,
                  ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Save Changes',
                  onPressed: () async {
                    if (_nameEdited && _nameController.text.trim().isNotEmpty) {
                      await groupsVm.renameGroup(widget.groupId, _nameController.text.trim());
                    }
                    if (context.mounted) {
                      AppToast.show(context, 'Group updated', type: AppToastType.success);
                      Navigator.of(context).pop();
                    }
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

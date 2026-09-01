import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/group_model.dart';
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
/// `isAdmin` and the current name are live via [GroupsViewModel] —
/// getting demoted or the name changing elsewhere updates this screen
/// without a refresh.
class GroupSettingsScreen extends StatefulWidget {
  const GroupSettingsScreen({super.key, required this.groupId, required this.groupName});

  final String groupId;
  final String groupName;

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  late final _nameController = TextEditingController(text: widget.groupName);
  bool _nameLoadedFromStream = false;
  bool _saving = false;

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
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
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
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context
          .read<GroupsViewModel>()
          .renameGroup(widget.groupId, _nameController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, "Couldn't save changes.", type: AppToastType.error);
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<GroupsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Group Settings')),
      body: SafeArea(
        child: StreamBuilder<GroupRole?>(
          stream: vm.watchMyRole(widget.groupId),
          builder: (context, roleSnap) {
            final isAdmin = roleSnap.data == GroupRole.admin;

            return StreamBuilder<Group?>(
              stream: vm.watchGroup(widget.groupId),
              builder: (context, groupSnap) {
                final group = groupSnap.data;
                if (group != null && !_nameLoadedFromStream) {
                  _nameLoadedFromStream = true;
                  _nameController.text = group.name;
                }

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Center(
                      child: AppAvatar(
                        name: _nameController.text,
                        imageUrl: group?.photoUrl,
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Group name',
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
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
                      isLoading: _saving,
                      onPressed: !_saving && _nameController.text.trim().isNotEmpty ? _save : null,
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

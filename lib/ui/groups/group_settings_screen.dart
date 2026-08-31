import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/list_row.dart';
import '../../widgets/inputs/app_text_field.dart';

/// Group Settings screen (product doc 5.6.5). Editable group name/photo,
/// Manage Members, Leave Group, and admin-only Delete Group.
///
/// TODO: `_isAdmin` and the demo name should come from a GroupsViewModel.
class GroupSettingsScreen extends StatefulWidget {
  const GroupSettingsScreen({super.key, required this.groupName});

  final String groupName;

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  static const _isAdmin = true;
  late final _nameController = TextEditingController(text: widget.groupName);

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
      // TODO: call GroupsViewModel.leaveGroup(...).
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
      // TODO: call GroupsViewModel.deleteGroup(...).
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Group Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(child: AppAvatar(name: _nameController.text, size: 80)),
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
                // TODO: push a Manage Members screen (remove/promote —
                // not separately specced in Part 5, folds into Group
                // Details' member list for now).
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ListRow(
              label: 'Leave Group',
              leading: const Icon(Icons.exit_to_app, color: AppColors.error),
              isDestructive: true,
              onTap: _leaveGroup,
            ),
            if (_isAdmin)
              ListRow(
                label: 'Delete Group',
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                isDestructive: true,
                onTap: _deleteGroup,
              ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Save Changes',
              onPressed: () {
                // TODO: call GroupsViewModel.renameGroup(...).
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

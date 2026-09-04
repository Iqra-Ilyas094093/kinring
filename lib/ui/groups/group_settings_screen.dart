import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/services/media_upload_service.dart';
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
/// current name/photo and admin check; [renameGroup]/[leaveGroup]/
/// [deleteGroup] for the actions. Photo (Phase 9): uploads through
/// [MediaUploadService] then [GroupsViewModel.updateGroupPhoto] — saves
/// immediately on pick, independent of the name's own Save button.
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
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(GroupsViewModel groupsVm) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await MediaUploadService.uploadImage(File(picked.path));
      await groupsVm.updateGroupPhoto(widget.groupId, url);
    } catch (e) {
      if (mounted) AppToast.show(context, 'Could not upload photo: $e', type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
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
        child: StreamBuilder<GroupModel?>(
          stream: groupsVm.listenGroup(widget.groupId),
          builder: (context, groupSnap) {
            final photoUrl = groupSnap.data?.photoUrl;
            return StreamBuilder<List<GroupMemberModel>>(
              stream: groupsVm.listenMembers(widget.groupId),
              builder: (context, memberSnap) {
                final members = memberSnap.data ?? const <GroupMemberModel>[];
                final isAdmin = members.any((m) => m.uid == myUid && m.isAdmin);

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _uploadingPhoto ? null : () => _pickPhoto(groupsVm),
                        child: Stack(
                          children: [
                            _uploadingPhoto
                                ? const SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                : AppAvatar(name: _nameController.text, imageUrl: photoUrl, size: 80),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, size: 14, color: AppColors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
            );
          },
        ),
      ),
    );
  }
}

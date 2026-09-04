import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/services/media_upload_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/feedback/app_toast.dart';
import '../../widgets/inputs/app_text_field.dart';
import 'invite_members_screen.dart';

/// Create Group screen (product doc 5.6.1). Group name + optional photo,
/// then straight into Invite Members so the creator can add people right
/// away.
///
/// Live data: [GroupsViewModel.createGroup] — the returned group's real
/// invite code is what Invite Members shows next. Photo (Phase 9):
/// picked via `image_picker`, uploaded to the `kinring-media-worker` R2
/// bucket via [MediaUploadService], then the returned URL is passed as
/// `photoUrl` to `createGroup`.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  bool _creating = false;
  bool _uploadingPhoto = false;
  String? _photoUrl;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await MediaUploadService.uploadImage(File(picked.path));
      if (!mounted) return;
      setState(() => _photoUrl = url);
    } catch (e) {
      if (mounted) AppToast.show(context, 'Could not upload photo: $e', type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _create() async {
    setState(() => _creating = true);
    final group = await context
        .read<GroupsViewModel>()
        .createGroup(_nameController.text.trim(), photoUrl: _photoUrl);
    if (!mounted) return;
    setState(() => _creating = false);
    if (group == null) {
      AppToast.show(context, 'Could not create group. Please try again.');
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => InviteMembersScreen(groupName: group.name, inviteCode: group.inviteCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Group')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _uploadingPhoto ? null : _pickPhoto,
                  child: Stack(
                    children: [
                      _uploadingPhoto
                          ? const SizedBox(
                              width: 88,
                              height: 88,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : AppAvatar(
                              name: _nameController.text.isEmpty ? '?' : _nameController.text,
                              imageUrl: _photoUrl,
                              size: 88,
                            ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Group name', style: textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Group name',
                controller: _nameController,
                hintText: 'e.g. Exam Squad',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: _creating ? 'Creating…' : 'Create Group',
                onPressed: _nameController.text.trim().isNotEmpty && !_creating ? _create : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

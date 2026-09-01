import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _submitting = true);
    try {
      final group = await context.read<GroupsViewModel>().createGroup(_nameController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => InviteMembersScreen(
            groupId: group.id,
            groupName: group.name,
            inviteCode: group.inviteCode,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, "Couldn't create group. Try again.", type: AppToastType.error);
      setState(() => _submitting = false);
    }
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
                child: Stack(
                  children: [
                    AppAvatar(
                      name: _nameController.text.isEmpty ? '?' : _nameController.text,
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
                label: 'Create Group',
                isLoading: _submitting,
                onPressed: !_submitting && _nameController.text.trim().isNotEmpty ? _create : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

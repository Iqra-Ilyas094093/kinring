import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/services/media_upload_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/list_row.dart';
import '../../widgets/feedback/app_toast.dart';
import '../../widgets/inputs/app_text_field.dart';
import 'change_password_screen.dart';

/// Account Settings screen (product doc 5.10.1). Editable Name/Email/
/// Phone, a link into Change Password, and Save.
///
/// Live data: initial values from [AuthViewModel.currentUser]; Save calls
/// [AuthViewModel.updateProfile]. Email is read-only here — changing it
/// needs Firebase Auth re-authentication, a separate flow not built yet.
/// Photo (Phase 9): uploads through [MediaUploadService] then
/// [AuthViewModel.updatePhoto] — saves immediately on pick, independent
/// of the Save button below (matches Group Settings' photo behavior).
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _phoneController = TextEditingController();
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _photoUrl = user?.photoURL;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await MediaUploadService.uploadImage(File(picked.path));
      final ok = await context.read<AuthViewModel>().updatePhoto(url);
      if (!mounted) return;
      if (ok) {
        setState(() => _photoUrl = url);
      } else {
        AppToast.show(context, 'Could not save photo. Please try again.', type: AppToastType.error);
      }
    } catch (e) {
      if (mounted) AppToast.show(context, 'Could not upload photo: $e', type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await context.read<AuthViewModel>().updateProfile(
          name: _nameController.text,
          phone: _phoneController.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      AppToast.show(context, 'Could not save changes. Please try again.');
      return;
    }
    AppToast.show(context, 'Account updated', type: AppToastType.success);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
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
                        : AppAvatar(name: _nameController.text, imageUrl: _photoUrl, size: 88),
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
            AppTextField(label: 'Name', controller: _nameController),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: false,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Phone',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              hintText: 'Optional',
            ),
            const SizedBox(height: AppSpacing.lg),
            ListRow(
              label: 'Change Password',
              leading: const Icon(Icons.lock_outline, color: AppColors.dark1),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: _saving ? 'Saving…' : 'Save Changes',
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

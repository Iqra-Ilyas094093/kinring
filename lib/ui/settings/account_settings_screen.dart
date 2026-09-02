import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/buttons/primary_button.dart';
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

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
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

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/feedback/app_toast.dart';
import '../../widgets/inputs/app_password_field.dart';

/// Change Password screen — reached from Account Settings' "Change
/// Password" row. Not a named screen in Part 5, but AppPasswordField's
/// doc comment lists "Change Password" as one of its three call sites,
/// so it gets its own screen rather than a cramped inline section.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _currentController.text.isNotEmpty &&
      _newController.text.length >= 8 &&
      _newController.text == _confirmController.text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Change Password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppPasswordField(
              label: 'Current Password',
              controller: _currentController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            AppPasswordField(
              label: 'New Password',
              controller: _newController,
              helperText: 'At least 8 characters',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            AppPasswordField(
              label: 'Confirm New Password',
              controller: _confirmController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Update Password',
              onPressed: _canSubmit
                  ? () {
                      // TODO: call AuthViewModel.changePassword(...)
                      AppToast.show(
                        context,
                        'Password updated',
                        type: AppToastType.success,
                      );
                      Navigator.of(context).pop();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

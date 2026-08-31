import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/auth_flow_status.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import 'reset_link_sent_screen.dart';

/// Forgot Password screen per product doc 5.4.4.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthViewModel authViewModel) async {
    final email = _emailController.text.trim();
    final success = await authViewModel.sendPasswordResetEmail(email);
    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResetLinkSentScreen(email: email)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final authViewModel = context.watch<AuthViewModel>();
    final isLoading = authViewModel.status == AuthFlowStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reset your password', style: textTheme.headlineLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "Enter your email and we'll send you a reset link.",
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) {
                  authViewModel.clearError();
                  setState(() {});
                },
              ),
              if (authViewModel.status == AuthFlowStatus.error) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  authViewModel.errorMessage ?? '',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Send Reset Link',
                isLoading: isLoading,
                onPressed: _emailController.text.trim().isNotEmpty && !isLoading
                    ? () => _submit(authViewModel)
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Back to Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

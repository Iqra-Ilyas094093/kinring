import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/auth_flow_status.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/buttons/google_signin_button.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/checkbox_row.dart';
import '../../widgets/common/or_divider.dart';
import '../../widgets/feedback/app_toast.dart';
import '../../widgets/inputs/app_password_field.dart';
import '../../widgets/inputs/app_text_field.dart';

/// Signup screen per product doc 5.4.2.
///
/// Same pattern as [LoginScreen]: only talks to [AuthViewModel]. After a
/// successful email/password signup, Firebase signs the user in
/// immediately (unverified) — popping to root lets [AuthGate] notice the
/// new (unverified) session and route to Email Verification on its own.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _passwordsMatch =>
      _passwordController.text.isNotEmpty && _passwordController.text == _confirmPasswordController.text;

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.length >= 8 &&
      _passwordsMatch &&
      _agreedToTerms;

  Future<void> _submit(AuthViewModel authViewModel) async {
    final success = await authViewModel.signUpWithEmail(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _submitGoogle(AuthViewModel authViewModel) async {
    final success = await authViewModel.signInWithGoogle();
    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (authViewModel.status == AuthFlowStatus.error && mounted) {
      AppToast.show(context, authViewModel.errorMessage ?? 'Google sign-in failed.', type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final authViewModel = context.watch<AuthViewModel>();
    final isLoading = authViewModel.status == AuthFlowStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const AppLogo(variant: AppLogoVariant.monogram),
              const SizedBox(height: AppSpacing.lg),
              Text('Create your account', style: textTheme.headlineLarge),
              const SizedBox(height: AppSpacing.xs),
              Text('Join a group and never miss a shared alarm.', style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),

              GoogleSignInButton(
                onPressed: isLoading ? null : () => _submitGoogle(authViewModel),
              ),
              const SizedBox(height: AppSpacing.lg),
              const OrDivider(),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                label: 'Name',
                controller: _nameController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) {
                  authViewModel.clearError();
                  setState(() {});
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppPasswordField(
                label: 'Password',
                controller: _passwordController,
                helperText: 'At least 8 characters',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPasswordField(
                label: 'Confirm Password',
                controller: _confirmPasswordController,
                errorText: _confirmPasswordController.text.isNotEmpty && !_passwordsMatch
                    ? "Passwords don't match"
                    : null,
                onChanged: (_) => setState(() {}),
              ),

              if (authViewModel.status == AuthFlowStatus.error) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  authViewModel.errorMessage ?? '',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
              ],

              const SizedBox(height: AppSpacing.sm),
              CheckboxRow(
                value: _agreedToTerms,
                onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
                label: Text('I agree to the Terms & Privacy Policy', style: textTheme.bodySmall),
              ),
              const SizedBox(height: AppSpacing.md),

              PrimaryButton(
                label: 'Sign Up',
                isLoading: isLoading,
                onPressed: _canSubmit && !isLoading ? () => _submit(authViewModel) : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              Center(
                child: TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Already have an account? Log In'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

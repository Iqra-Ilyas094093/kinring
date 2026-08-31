import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/auth_flow_status.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/buttons/google_signin_button.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/or_divider.dart';
import '../../widgets/feedback/app_toast.dart';
import '../../widgets/inputs/app_password_field.dart';
import '../../widgets/inputs/app_text_field.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

/// Login screen per product doc 5.4.1.
///
/// Talks only to [AuthViewModel] — never to Firebase or Google directly.
/// On a successful sign-in, [AuthGate] (watching the same view model's
/// auth stream) will swap in the right screen once this route pops back
/// to root, so this screen's only job after success is to get out of the
/// way.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty && _passwordController.text.isNotEmpty;

  Future<void> _submit(AuthViewModel authViewModel) async {
    final success = await authViewModel.signInWithEmail(
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogo(variant: AppLogoVariant.monogram),
              const SizedBox(height: AppSpacing.lg),
              Text('Welcome back', style: textTheme.headlineLarge),
              const SizedBox(height: AppSpacing.xs),
              Text('Log in to keep your groups in sync.', style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),

              GoogleSignInButton(
                onPressed: isLoading ? null : () => _submitGoogle(authViewModel),
              ),
              const SizedBox(height: AppSpacing.lg),
              const OrDivider(),
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
              const SizedBox(height: AppSpacing.md),
              AppPasswordField(
                label: 'Password',
                controller: _passwordController,
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

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          ),
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              PrimaryButton(
                label: 'Log In',
                isLoading: isLoading,
                onPressed: _canSubmit && !isLoading ? () => _submit(authViewModel) : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              Center(
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignupScreen()),
                          ),
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

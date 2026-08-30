import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/secondary_button.dart';
import '../../widgets/common/app_logo.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

/// First screen a new/logged-out user sees. Introduces the app and offers
/// a choice before committing to Login or Signup. Per product doc 5.3.
///
/// Pure UI — no view model needed here, since this screen holds no state
/// beyond navigation taps.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Spacer(),
              Text(
                'One ring, everyone in',
                style: textTheme.displayMedium,
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Set alarms and reminders your whole group shares.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Log In',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: 'Sign Up',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

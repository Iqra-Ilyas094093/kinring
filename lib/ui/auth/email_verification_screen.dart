import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common/note_text.dart';
import '../core_navigation/core_navigation_screen.dart';

/// Email Verification screen per product doc 5.4.3.
///
/// Polls Firebase every few seconds and, once verified, replaces the
/// entire navigation stack with [CoreNavigationScreen] directly — a
/// manual `reload()` does not emit a new `authStateChanges` event, so
/// [AuthGate] alone would not notice this change.
///
/// Simplification vs. the doc: manual 6-digit code entry isn't
/// implemented (that needs a custom backend flow beyond Firebase's
/// built-in verification links) — only the email-link path is wired up.
/// "Change email address" signs the unverified account out rather than
/// returning to a pre-filled Signup screen, to avoid duplicating signup
/// state here.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const _cooldownSeconds = 30;
  int _remainingCooldown = _cooldownSeconds;
  Timer? _cooldownTimer;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkVerified());
  }

  void _startCooldown() {
    _remainingCooldown = _cooldownSeconds;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingCooldown <= 1) {
        timer.cancel();
        setState(() => _remainingCooldown = 0);
      } else {
        setState(() => _remainingCooldown--);
      }
    });
  }

  Future<void> _checkVerified() async {
    final authViewModel = context.read<AuthViewModel>();
    final verified = await authViewModel.reloadAndCheckVerified();
    if (verified && mounted) {
      _pollTimer?.cancel();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CoreNavigationScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _resend(AuthViewModel authViewModel) async {
    await authViewModel.resendVerificationEmail();
    if (mounted) _startCooldown();
  }

  Future<void> _changeEmail(AuthViewModel authViewModel) async {
    await authViewModel.signOut();
    // AuthGate (root) will now see no user and show WelcomeScreen — pop
    // this whole stack back to it.
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final authViewModel = context.watch<AuthViewModel>();
    final email = authViewModel.currentUser?.email ?? 'your email';
    final canResend = _remainingCooldown == 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 64, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              Text('Verify your email', style: textTheme.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'We sent a verification link to $email',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              const NoteText(text: "Didn't get it? Check your spam or junk folder."),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: canResend ? () => _resend(authViewModel) : null,
                child: Text(canResend ? 'Resend Email' : 'Resend Email (${_remainingCooldown}s)'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => _changeEmail(authViewModel),
                child: const Text('Change email address'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

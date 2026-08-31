import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/note_text.dart';

/// Reset Link Sent screen per product doc 5.4.5.
class ResetLinkSentScreen extends StatefulWidget {
  const ResetLinkSentScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetLinkSentScreen> createState() => _ResetLinkSentScreenState();
}

class _ResetLinkSentScreenState extends State<ResetLinkSentScreen> {
  static const _cooldownSeconds = 30;
  int _remainingCooldown = _cooldownSeconds;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
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

  Future<void> _resend(AuthViewModel authViewModel) async {
    await authViewModel.sendPasswordResetEmail(widget.email);
    if (mounted) _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final authViewModel = context.watch<AuthViewModel>();
    final canResend = _remainingCooldown == 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 64, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              Text('Check your email', style: textTheme.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'We sent a password reset link to ${widget.email}',
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
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Back to Login',
                onPressed: () => Navigator.of(context)
                  ..pop()
                  ..pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/fcm_service.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../core_navigation/core_navigation_screen.dart';
import '../welcome/welcome_screen.dart';
import 'email_verification_screen.dart';

/// Root-level routing gate. There is no custom splash screen anymore —
/// the platform's native launch screen (already configured) covers the
/// brief moment before Flutter renders its first frame, and this widget
/// is that first frame.
///
/// It watches [AuthViewModel.authStateChanges] and shows:
/// - [WelcomeScreen] — no signed-in user
/// - [EmailVerificationScreen] — signed in with email/password but not
///   yet verified (Google accounts are always pre-verified, so they skip
///   this)
/// - [CoreNavigationScreen] — signed in and verified
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return StreamBuilder<User?>(
      stream: authViewModel.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const WelcomeScreen();
        }

        final isGoogleAccount = user.providerData.any((p) => p.providerId == 'google.com');
        if (!isGoogleAccount && !user.emailVerified) {
          return const EmailVerificationScreen();
        }

        // Phase 5 — fire-and-forget, every time this branch is reached
        // (not just first sign-in): cheap arrayUnion, and it's how a
        // second device or a reinstall gets its token registered too.
        FcmService.syncTokenForCurrentUser();

        return const CoreNavigationScreen();
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/auth_status.dart';
import '../../viewmodels/splash_viewmodel.dart';
import '../../widgets/common/app_logo.dart';
import '../welcome/welcome_screen.dart';

/// Brief brand moment while the app checks login state, then routes
/// forward. No user interaction.
///
/// This widget is pure UI — the actual session check lives in
/// [SplashViewModel]. It provides its own viewmodel instance since the
/// check only matters for this one screen's lifetime.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SplashViewModel()..checkSession(),
      child: const _SplashView(),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SplashViewModel>();
    final textTheme = Theme.of(context).textTheme;

    // React to the session check completing. This runs after the current
    // frame so it's safe to navigate from inside build().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      switch (viewModel.status) {
        case AuthStatus.checking:
          break;
        case AuthStatus.loggedOut:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          );
        case AuthStatus.loggedIn:
          // TODO(nav): route to Core Navigation (Home) once it exists.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          );
        case AuthStatus.emailUnverified:
          // TODO(nav): route to Email Verification Screen once it exists.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(variant: AppLogoVariant.full),
            const SizedBox(height: 24),
            Text('One ring, everyone in.', style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';

enum AppLogoVariant { full, monogram, wordmark }

/// Renders the KinRing logo. Use [AppLogoVariant.full] for splash/marketing,
/// [AppLogoVariant.monogram] for compact spaces (app bar, nav), and
/// [AppLogoVariant.wordmark] where just the name is needed.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.variant = AppLogoVariant.full,
    this.height,
  });

  final AppLogoVariant variant;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final path = switch (variant) {
      AppLogoVariant.full => AppAssets.logoFull,
      AppLogoVariant.monogram => AppAssets.logoMonogram,
      AppLogoVariant.wordmark => AppAssets.logoWordmark,
    };

    return Center(
      child: Image.asset(
        path,
        height: height ?? (variant == AppLogoVariant.monogram ? 80 : 120),
        fit: BoxFit.contain,
      ),
    );
  }
}

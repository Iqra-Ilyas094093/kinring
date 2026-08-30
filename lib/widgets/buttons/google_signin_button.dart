import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// "Continue with Google" button. Used on Login and Signup screens.
///
/// Note: `AppAssets.googleLogo` isn't bundled in this project yet — until
/// that asset is added, this renders a plain "G" glyph as a placeholder so
/// the layout is correct today and upgrades automatically once the real
/// mark is dropped in.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.label = 'Continue with Google',
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: AppSpacing.buttonHeight,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.dark1,
          side: const BorderSide(color: AppColors.border),
          backgroundColor: AppColors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppAssets.googleLogo,
              height: 20,
              width: 20,
              errorBuilder: (context, error, stackTrace) => Text(
                'G',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.dark1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: textTheme.labelLarge?.copyWith(color: AppColors.dark1),
            ),
          ],
        ),
      ),
    );
  }
}

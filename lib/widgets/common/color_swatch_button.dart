import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Tappable color/shade square. Used on the Color Match Task Screen, both
/// in the flashing sequence preview (via [active]) and in the shuffled
/// answer grid.
class ColorSwatchButton extends StatelessWidget {
  const ColorSwatchButton({
    super.key,
    required this.color,
    this.onTap,
    this.active = false,
    this.size = 72,
    this.patternIcon,
  });

  final Color color;
  final VoidCallback? onTap;
  final bool active;
  final double size;

  /// Phase 10 — Accessibility "Colorblind pattern mode". When set, a
  /// small glyph unique to this color is drawn on top of it, so the
  /// task doesn't rely on hue discrimination alone. `null` (the
  /// default) renders the plain swatch, unchanged from before this was
  /// wired up.
  final IconData? patternIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: active ? AppColors.white : AppColors.transparent,
            width: 3,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: patternIcon == null
            ? null
            : Icon(patternIcon, color: AppColors.white, size: size * 0.42, shadows: const [
                Shadow(color: AppColors.dark1, blurRadius: 4),
              ]),
      ),
    );
  }
}

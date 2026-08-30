import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Tappable settings-style row: optional leading icon, label, optional
/// subtitle, and a trailing chevron. Used on Settings, Account Settings,
/// Group Settings, About/Help, Admin Panel.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.label,
    this.subtitle,
    this.leading,
    this.onTap,
    this.isDestructive = false,
    this.showChevron = true,
  });

  final String label;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelColor = isDestructive ? AppColors.error : AppColors.dark1;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm + 4,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.md)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textTheme.bodyLarge?.copyWith(color: labelColor)),
                  if (subtitle != null)
                    Text(subtitle!, style: textTheme.bodySmall),
                ],
              ),
            ),
            if (showChevron && !isDestructive)
              const Icon(Icons.chevron_right, color: AppColors.dark2),
          ],
        ),
      ),
    );
  }
}

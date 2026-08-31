import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';

/// Icon, event title, group name, and a short preview of the action
/// needed, with two inline actions ("Open" always; "Got it" only for
/// simple-tap reminders). Mirrors the real Android notification's layout
/// so the in-app preview (see [ReminderNotificationCardScreen]) matches
/// what fires once push delivery is wired up.
class ReminderNotificationCard extends StatelessWidget {
  const ReminderNotificationCard({
    super.key,
    required this.title,
    required this.groupName,
    required this.previewText,
    required this.onOpen,
    this.onGotIt,
  });

  final String title;
  final String groupName;
  final String previewText;
  final VoidCallback onOpen;
  final VoidCallback? onGotIt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark1.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.light1,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.notifications_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleLarge),
                    Text(groupName, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(previewText, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(label: 'Open', onPressed: onOpen),
              ),
              if (onGotIt != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(label: 'Got it', onPressed: onGotIt),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

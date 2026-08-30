import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum EventMemberStatus { cleared, ringing, snoozed, pending }

/// Colored pill label. Used on Live Group Status Screen and Upcoming Event
/// Detail.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final EventMemberStatus status;

  ({Color bg, Color fg, String label}) get _style => switch (status) {
        EventMemberStatus.cleared => (
            bg: AppColors.statusCleared,
            fg: AppColors.white,
            label: 'Cleared',
          ),
        EventMemberStatus.ringing => (
            bg: AppColors.statusRinging,
            fg: AppColors.white,
            label: 'Ringing',
          ),
        EventMemberStatus.snoozed => (
            bg: AppColors.statusSnoozed,
            fg: AppColors.white,
            label: 'Snoozed',
          ),
        EventMemberStatus.pending => (
            bg: AppColors.statusPendingBg,
            fg: AppColors.statusPendingText,
            label: 'Pending',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        s.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: s.fg,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

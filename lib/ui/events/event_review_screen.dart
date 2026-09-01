import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/feedback/app_toast.dart';

/// Event Summary/Review screen (product doc 5.7.4). Read-only summary of
/// everything set in the previous steps, then Confirm & Create.
class EventReviewScreen extends StatelessWidget {
  const EventReviewScreen({super.key, required this.draft});

  final EventDraft draft;

  Widget _row(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: textTheme.bodySmall)),
          Expanded(child: Text(value, style: textTheme.bodyLarge)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = draft.title.trim().isEmpty
        ? (draft.kind == EventKind.alarm ? 'Alarm' : 'Reminder')
        : draft.title.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Review Event')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    draft.kind == EventKind.alarm ? Icons.alarm_rounded : Icons.notifications_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(title, style: textTheme.headlineMedium),
                ],
              ),
              const Divider(color: AppColors.border, height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _row(context, 'Group', draft.groupName),
                    const Divider(color: AppColors.border, height: 1),
                    _row(context, 'Date', draft.dateLabel),
                    const Divider(color: AppColors.border, height: 1),
                    _row(context, 'Time', draft.timeLabel),
                    const Divider(color: AppColors.border, height: 1),
                    _row(context, 'Repeat', draft.repeatLabel),
                    const Divider(color: AppColors.border, height: 1),
                    _row(context, 'Task', draft.taskLabel),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Confirm & Create',
                onPressed: () {
                  // TODO: call EventsViewModel.createEvent(draft) — this
                  // is where the local exact alarm (AlarmManager) and the
                  // Cloudflare Worker sync get scheduled per doc Part 3.
                  AppToast.show(context, 'Event created', type: AppToastType.success);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

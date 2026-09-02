import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
import '../../viewmodels/events_viewmodel.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/feedback/app_toast.dart';

/// Event Summary/Review screen (product doc 5.7.4). Read-only summary of
/// everything set in the previous steps, then Confirm & Create.
///
/// Live data: [EventsViewModel.createEvent] — this is where the Firestore
/// write, the device-local exact alarm (Phase 4), and eventually the
/// Cloudflare cron sync (Phase 6, already built) all get scheduled.
class EventReviewScreen extends StatefulWidget {
  const EventReviewScreen({super.key, required this.draft});

  final EventDraft draft;

  @override
  State<EventReviewScreen> createState() => _EventReviewScreenState();
}

class _EventReviewScreenState extends State<EventReviewScreen> {
  bool _creating = false;

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

  Future<void> _confirm() async {
    setState(() => _creating = true);
    final group = await context.read<GroupsViewModel>().listenGroup(widget.draft.groupId).first;
    final memberIds = group?.memberIds ?? const <String>[];
    final eventId = await context
        .read<EventsViewModel>()
        .createEvent(widget.draft, memberIds: memberIds);
    if (!mounted) return;
    setState(() => _creating = false);
    if (eventId == null) {
      AppToast.show(context, 'Could not create event. Please try again.');
      return;
    }
    AppToast.show(context, 'Event created', type: AppToastType.success);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final draft = widget.draft;
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
                label: _creating ? 'Creating…' : 'Confirm & Create',
                onPressed: _creating ? null : _confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

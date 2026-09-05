import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/services/alarm_scheduler.dart';
import '../../core/services/local_notifications_service.dart';
import '../../models/event_draft.dart';
import '../../viewmodels/event_status_viewmodel.dart';
import '../../widgets/common/reminder_notification_card.dart';
import 'task_cleared_confirmation_screen.dart';
import 'type_confirm_task_screen.dart';

/// Reminder Notification Card (product doc 5.8.4). Reminders are a soft
/// task — unlike the Alarm Ringing Screen, there's no full-screen hard
/// gate here, just a notification-style card.
///
/// TODO(backend wiring): the real card is an Android system notification
/// (FCM data message → flutter_local_notifications), with "Open" and
/// "Got it" as native notification actions. This screen renders the same
/// [ReminderNotificationCard] content in-app so the tap-through targets
/// (Type & Confirm / cleared) can be built and tested before that wiring
/// lands.
class ReminderNotificationCardScreen extends StatelessWidget {
  ReminderNotificationCardScreen({super.key, required this.draft, DateTime? startedAt})
      : startedAt = startedAt ?? DateTime.now();

  final EventDraft draft;
  final DateTime startedAt;

  void _openTask(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TypeConfirmTaskScreen(draft: draft, startedAt: startedAt),
      ),
    );
  }

  void _gotIt(BuildContext context) {
    // Phase 8 fix: this shortcut (useSimpleTap reminders) used to skip
    // straight to the confirmation screen without ever writing the
    // status doc — Live Status stayed "Pending" forever because nothing
    // told it otherwise. Same fire-and-forget write as the other two
    // task screens.
    EventStatusViewModel().markCleared(groupId: draft.groupId, eventId: draft.eventId);
    if (draft.eventId != null) {
      LocalNotificationsService.dismiss(AlarmScheduler.alarmIdFor(draft.eventId!));
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskClearedConfirmationScreen(draft: draft, startedAt: startedAt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = draft.title.trim().isEmpty ? 'Reminder' : draft.title.trim();
    final previewText = draft.useSimpleTap
        ? 'Tap "Got it" to confirm you\'ve done this.'
        : 'Type "${draft.confirmationPhrase}" to confirm.';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reminder')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ReminderNotificationCard(
            title: title,
            groupName: draft.groupName,
            previewText: previewText,
            onOpen: () => _openTask(context),
            onGotIt: draft.useSimpleTap ? () => _gotIt(context) : null,
          ),
        ),
      ),
    );
  }
}
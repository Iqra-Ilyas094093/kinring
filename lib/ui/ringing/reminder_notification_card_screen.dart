import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/services/alarm_audio_service.dart';
import '../../core/services/alarm_scheduler.dart';
import '../../core/services/local_notifications_service.dart';
import '../../models/event_draft.dart';
import '../../models/event_status_model.dart';
import '../../viewmodels/event_status_viewmodel.dart';
import '../../widgets/common/reminder_notification_card.dart';
import '../../widgets/common/status_badge.dart';
import '../core_navigation/core_navigation_screen.dart';
import 'task_cleared_confirmation_screen.dart';
import 'type_confirm_task_screen.dart';

/// Reminder Notification Card (product doc 5.8.4). Full-screen — same
/// PopScope-blocked, admin-force-stoppable treatment as
/// [AlarmRingingScreen].
class ReminderNotificationCardScreen extends StatefulWidget {
  ReminderNotificationCardScreen({super.key, required this.draft, DateTime? startedAt})
      : startedAt = startedAt ?? DateTime.now();

  final EventDraft draft;
  final DateTime startedAt;

  @override
  State<ReminderNotificationCardScreen> createState() => _ReminderNotificationCardScreenState();
}

class _ReminderNotificationCardScreenState extends State<ReminderNotificationCardScreen> {
  final _statusVm = EventStatusViewModel();
  StreamSubscription<EventStatusModel?>? _statusSub;
  bool _forceStopped = false;

  @override
  void initState() {
    super.initState();
    final eventId = widget.draft.eventId;
    if (eventId != null) {
      _statusVm.markRinging(groupId: widget.draft.groupId, eventId: eventId);
      _statusSub = _statusVm
          .listenMyStatus(groupId: widget.draft.groupId, eventId: eventId)
          .listen(_onStatusChanged);
    }
  }

  void _onStatusChanged(EventStatusModel? status) {
    if (_forceStopped || !mounted) return;
    if (status?.status == EventMemberStatus.cleared && status?.forceStoppedByAdmin == true) {
      _forceStopped = true;
      AlarmAudioService.stopReminderSound();
      final eventId = widget.draft.eventId;
      if (eventId != null) {
        LocalNotificationsService.dismiss(AlarmScheduler.alarmIdFor(eventId));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An admin stopped this reminder for you.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CoreNavigationScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  void _openTask(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TypeConfirmTaskScreen(draft: widget.draft, startedAt: widget.startedAt),
      ),
    );
  }

  void _gotIt(BuildContext context) {
    EventStatusViewModel().markCleared(groupId: widget.draft.groupId, eventId: widget.draft.eventId);
    if (widget.draft.eventId != null) {
      LocalNotificationsService.dismiss(AlarmScheduler.alarmIdFor(widget.draft.eventId!));
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskClearedConfirmationScreen(draft: widget.draft, startedAt: widget.startedAt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final title = draft.title.trim().isEmpty ? 'Reminder' : draft.title.trim();
    final previewText = draft.useSimpleTap
        ? 'Tap "Got it" to confirm you\'ve done this.'
        : 'Type "${draft.confirmationPhrase}" to confirm.';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Reminder'), automaticallyImplyLeading: false),
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
      ),
    );
  }
}

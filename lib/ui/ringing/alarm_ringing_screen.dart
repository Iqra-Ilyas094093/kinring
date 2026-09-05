import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/alarm_scheduler.dart';
import '../../core/services/local_notifications_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
import '../../viewmodels/events_viewmodel.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../core_navigation/core_navigation_screen.dart';
import 'color_match_task_screen.dart';

/// Alarm Ringing Screen (product doc 5.8.1). Full-screen, no status bar or
/// back navigation — the only way off this screen is to clear the task
/// ("Tap to Stop") or, if the admin allowed it for this event, to snooze.
///
/// Snooze: [_handleSnooze] moves the event's `timeUTC` 5 minutes out via
/// [EventsViewModel.snoozeEvent] — kinring-cron's existing per-minute
/// backup push naturally re-fires it for the WHOLE group when that
/// arrives, not just this device (see that method's doc comment for
/// why bumping `timeUTC` alone is enough). This device also schedules
/// its own local re-fire via [AlarmScheduler.scheduleSnoozeFor] for
/// offline safety, same as the primary local-alarm-plus-cron-backup
/// pattern used everywhere else. Previously this just re-pushed the
/// same screen immediately with no real delay and no effect on anyone
/// else's device — snoozing silently "solved" the alarm for good.
///
/// TODO(backend wiring): still needs `screen_brightness` to force max
/// brightness per the doc.
class AlarmRingingScreen extends StatefulWidget {
  AlarmRingingScreen({
    super.key,
    required this.draft,
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  final EventDraft draft;
  final DateTime startedAt;

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with SingleTickerProviderStateMixin {
  static const _snoozeDuration = Duration(minutes: 5);

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleSnooze() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Snooze for 5 min',
      message:
          "It'll ring again for the WHOLE group in 5 minutes — snoozing doesn't stop it for anyone, it just delays it.",
      confirmLabel: 'Snooze 5 min',
    );
    if (!confirmed || !mounted) return;

    final draft = widget.draft;
    final eventId = draft.eventId;
    final newSnoozeCount = draft.snoozeCount + 1;
    final fireAt = DateTime.now().add(_snoozeDuration);

    if (eventId != null) {
      // Bumps the event's timeUTC forward — kinring-cron picks this up
      // at fireAt and pushes to EVERY member, not just this device (see
      // EventsViewModel.snoozeEvent for why that's enough on its own).
      await context.read<EventsViewModel>().snoozeEvent(
            groupId: draft.groupId,
            eventId: eventId,
            newSnoozeCount: newSnoozeCount,
            delay: _snoozeDuration,
          );
      // This device's own offline-safe local re-fire — belt-and-suspenders
      // alongside the cron pickup above, same reasoning as the primary
      // local-alarm-plus-cron-backup design everywhere else in the app.
      await AlarmScheduler.scheduleSnoozeFor(draft.withSnoozeCount(newSnoozeCount), fireAt);
    }

    // The alarm is asleep for 5 minutes now — dismiss this device's
    // notification/screen and go back to Home rather than sitting on a
    // frozen ringing screen doing nothing for 5 minutes.
    if (eventId != null) {
      await LocalNotificationsService.dismiss(AlarmScheduler.alarmIdFor(eventId));
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CoreNavigationScreen()),
      (route) => false,
    );
  }

  void _handleTapToStop() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ColorMatchTaskScreen(
          draft: widget.draft,
          startedAt: widget.startedAt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = widget.draft.title.trim().isEmpty ? 'Alarm' : widget.draft.title.trim();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.dark1,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl),
                Text(
                  title,
                  style: textTheme.headlineLarge?.copyWith(color: AppColors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.draft.groupName,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.light2),
                ),
                const Spacer(),
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.15).animate(
                    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    size: 120,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _LiveClock(),
                const Spacer(),
                PrimaryButton(label: 'Tap to Stop', onPressed: _handleTapToStop),
                if (widget.draft.snoozeEnabled) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: _handleSnooze,
                    style: TextButton.styleFrom(foregroundColor: AppColors.white),
                    child: const Text('Snooze for 5 min'),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Live clock, local to this screen — the ringing screen shows the
/// current time next to the bell, distinct from [CountdownText]'s
/// elapsed/countdown role elsewhere in the app.
class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late DateTime _now = DateTime.now();
  late final Stream<DateTime> _ticker =
      Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: _ticker,
      initialData: _now,
      builder: (context, snapshot) {
        final now = snapshot.data ?? _now;
        final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
        final m = now.minute.toString().padLeft(2, '0');
        final period = now.hour >= 12 ? 'PM' : 'AM';
        return Text(
          '$h:$m $period',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(color: AppColors.white),
        );
      },
    );
  }
}

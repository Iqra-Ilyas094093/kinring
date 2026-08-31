import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/confirmation_dialog.dart';
import 'color_match_task_screen.dart';

/// Alarm Ringing Screen (product doc 5.8.1). Full-screen, no status bar or
/// back navigation — the only way off this screen is to clear the task
/// ("Tap to Stop") or, if the admin allowed it for this event, to snooze.
///
/// TODO(backend wiring): this screen is the target of the exact-alarm
/// trigger fired by Android `AlarmManager` (product doc Part 3, step 3).
/// It should also force screen brightness to maximum per the doc — add
/// the `screen_brightness` plugin when wiring the trigger itself.
class AlarmRingingScreen extends StatefulWidget {
  AlarmRingingScreen({
    super.key,
    required this.draft,
    DateTime? startedAt,
    this.snoozeCount = 0,
  }) : startedAt = startedAt ?? DateTime.now();

  final EventDraft draft;
  final DateTime startedAt;

  /// How many times this event has already been snoozed. Drives Color
  /// Match sequence length ("difficulty increases with each snooze").
  final int snoozeCount;

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with SingleTickerProviderStateMixin {
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
      title: 'Snooze',
      message: 'Snoozing will increase task difficulty.',
      confirmLabel: 'Snooze',
    );
    if (!confirmed || !mounted) return;

    // TODO(backend wiring): a real snooze reschedules the next ring via
    // AlarmManager rather than re-pushing this screen immediately.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AlarmRingingScreen(
          draft: widget.draft,
          startedAt: widget.startedAt,
          snoozeCount: widget.snoozeCount + 1,
        ),
      ),
    );
  }

  void _handleTapToStop() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ColorMatchTaskScreen(
          draft: widget.draft,
          startedAt: widget.startedAt,
          snoozeCount: widget.snoozeCount,
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
                    child: const Text('Snooze'),
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

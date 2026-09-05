import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/services/alarm_scheduler.dart';
import '../../core/services/local_notifications_service.dart';
import '../../models/event_draft.dart';
import '../../viewmodels/event_status_viewmodel.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import 'task_cleared_confirmation_screen.dart';

/// Type & Confirm Task Screen (product doc 5.8.5). Two variants driven by
/// [EventDraft.useSimpleTap]: a phrase the member must retype exactly, or
/// — when no phrase was set — a single large "Got it" button.
class TypeConfirmTaskScreen extends StatefulWidget {
  const TypeConfirmTaskScreen({super.key, required this.draft, required this.startedAt});

  final EventDraft draft;
  final DateTime startedAt;

  @override
  State<TypeConfirmTaskScreen> createState() => _TypeConfirmTaskScreenState();
}

class _TypeConfirmTaskScreenState extends State<TypeConfirmTaskScreen> {
  final _controller = TextEditingController();
  String _input = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _matches =>
      _input.trim().toLowerCase() == widget.draft.confirmationPhrase.trim().toLowerCase();

  void _confirm() {
    // Phase 8: fire-and-forget, see ColorMatchTaskScreen for why.
    EventStatusViewModel().markCleared(groupId: widget.draft.groupId, eventId: widget.draft.eventId);
    if (widget.draft.eventId != null) {
      LocalNotificationsService.dismiss(AlarmScheduler.alarmIdFor(widget.draft.eventId!));
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskClearedConfirmationScreen(
          draft: widget.draft,
          startedAt: widget.startedAt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = widget.draft.title.trim().isEmpty ? 'Reminder' : widget.draft.title.trim();
    final isSimpleTap = widget.draft.useSimpleTap;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.draft.groupName, style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xl),
              if (isSimpleTap) ...[
                const Spacer(),
                Center(
                  child: Icon(Icons.check_circle_outline_rounded, size: 72, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text(
                    'Confirm you\'ve done this',
                    style: textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(),
                PrimaryButton(label: 'Got it', onPressed: _confirm),
              ] else ...[
                Text('Type the phrase to confirm', style: textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.light1,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    widget.draft.confirmationPhrase,
                    style: textTheme.headlineLarge?.copyWith(color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Type the phrase',
                  controller: _controller,
                  onChanged: (v) => setState(() => _input = v),
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Confirm',
                  onPressed: _matches ? _confirm : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

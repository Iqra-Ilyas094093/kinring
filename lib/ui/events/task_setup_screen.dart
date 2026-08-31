import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/common/note_text.dart';
import '../../widgets/common/toggle_row.dart';
import '../../widgets/inputs/app_text_field.dart';
import 'event_review_screen.dart';

/// Task Setup screen (product doc 5.7.3). Fixed Color Match info card for
/// Alarms; confirmation-phrase input (or simple-tap toggle) for Reminders.
class TaskSetupScreen extends StatefulWidget {
  const TaskSetupScreen({super.key, required this.draft});

  final EventDraft draft;

  @override
  State<TaskSetupScreen> createState() => _TaskSetupScreenState();
}

class _TaskSetupScreenState extends State<TaskSetupScreen> {
  late final _phraseController = TextEditingController(text: widget.draft.confirmationPhrase);

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      widget.draft.kind == EventKind.alarm ||
      widget.draft.useSimpleTap ||
      _phraseController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isAlarm = widget.draft.kind == EventKind.alarm;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isAlarm ? 'Task: Color Match' : 'Set Confirmation Phrase')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAlarm) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.light1,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.grid_view_rounded, size: 48, color: AppColors.primary),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Watch a sequence of colors flash, then repeat it back in the same order to silence the alarm.',
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const NoteText(text: 'Difficulty increases with each snooze.'),
              ] else ...[
                ToggleRow(
                  label: 'Use simple tap instead',
                  subtitle: 'Members tap "Got it" — no phrase to type',
                  value: widget.draft.useSimpleTap,
                  onChanged: (v) => setState(() => widget.draft.useSimpleTap = v),
                ),
                if (!widget.draft.useSimpleTap) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Confirmation phrase',
                    controller: _phraseController,
                    hintText: 'e.g. standup 9am',
                    maxLength: 30,
                    onChanged: (v) => setState(() => widget.draft.confirmationPhrase = v),
                  ),
                ],
              ],
              const Spacer(),
              PrimaryButton(
                label: 'Next',
                onPressed: _canProceed
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EventReviewScreen(draft: widget.draft),
                          ),
                        )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

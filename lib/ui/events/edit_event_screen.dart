import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/common/note_text.dart';
import '../../widgets/common/toggle_row.dart';
import '../../widgets/feedback/app_toast.dart';
import '../../widgets/inputs/app_text_field.dart';

/// Edit Event screen (product doc 5.7.6). Same fields as the Create
/// Event flow, combined onto one screen and pre-filled, per the doc:
/// "Same layout as Create Event (combined, pre-filled)".
class EditEventScreen extends StatefulWidget {
  const EditEventScreen({super.key, required this.draft});

  final EventDraft draft;

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  late final _phraseController = TextEditingController(text: widget.draft.confirmationPhrase);

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.draft.date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => widget.draft.date = picked);
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final initial = widget.draft.time != null
        ? TimeOfDay(hour: widget.draft.time!.hour, minute: widget.draft.time!.minute)
        : TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() => widget.draft.time = DateTime(now.year, now.month, now.day, picked.hour, picked.minute));
    }
  }

  Widget _repeatChip(RepeatRule rule, String label) {
    final selected = widget.draft.repeatRule == rule;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => widget.draft.repeatRule = rule),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: selected ? AppColors.white : AppColors.dark1),
      backgroundColor: AppColors.white,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isAlarm = widget.draft.kind == EventKind.alarm;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Event')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Group: ${widget.draft.groupName}', style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            Text('Date', style: textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
              label: Text(widget.draft.dateLabel),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Time', style: textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.access_time, color: AppColors.primary),
              label: Text(widget.draft.timeLabel),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Repeat', style: textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                _repeatChip(RepeatRule.once, 'Once'),
                _repeatChip(RepeatRule.daily, 'Daily'),
                _repeatChip(RepeatRule.weekly, 'Weekly'),
                _repeatChip(RepeatRule.custom, 'Custom'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isAlarm)
              const NoteText(text: 'Task: Color Match — difficulty increases with each snooze.')
            else ...[
              ToggleRow(
                label: 'Use simple tap instead',
                value: widget.draft.useSimpleTap,
                onChanged: (v) => setState(() => widget.draft.useSimpleTap = v),
              ),
              if (!widget.draft.useSimpleTap) ...[
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Confirmation phrase',
                  controller: _phraseController,
                  maxLength: 30,
                  onChanged: (v) => setState(() => widget.draft.confirmationPhrase = v),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Save Changes',
              onPressed: () {
                // TODO: call EventsViewModel.updateEvent(draft).
                AppToast.show(context, 'Event updated', type: AppToastType.success);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

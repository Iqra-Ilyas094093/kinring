import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
import '../../widgets/buttons/primary_button.dart';
import 'task_setup_screen.dart';

/// Time & Repeat Setup screen (product doc 5.7.2). Date + time pickers
/// and a repeat-rule chip row, with a day-of-week selector for Custom.
class EventTimeSetupScreen extends StatefulWidget {
  const EventTimeSetupScreen({super.key, required this.draft});

  final EventDraft draft;

  @override
  State<EventTimeSetupScreen> createState() => _EventTimeSetupScreenState();
}

class _EventTimeSetupScreenState extends State<EventTimeSetupScreen> {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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

  bool get _canProceed => widget.draft.date != null && widget.draft.time != null;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Set Time')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
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
            if (widget.draft.repeatRule == RepeatRule.custom) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                children: _weekdays.map((day) {
                  final selected = widget.draft.customDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      v ? widget.draft.customDays.add(day) : widget.draft.customDays.remove(day);
                    }),
                    selectedColor: AppColors.light2,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Next',
              onPressed: _canProceed
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TaskSetupScreen(draft: widget.draft),
                        ),
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

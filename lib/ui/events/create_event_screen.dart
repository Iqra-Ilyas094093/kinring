import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/event_card.dart';
import 'event_time_setup_screen.dart';

/// Create Event screen (product doc 5.7.1). Type selector (Alarm vs
/// Reminder, two large cards) + group selector, then into Time & Repeat
/// Setup.
///
/// TODO: `_demoGroups` should come from a GroupsViewModel (the groups
/// the current user belongs to).
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key, this.preselectedGroup});

  final String? preselectedGroup;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  static const _demoGroups = ['Exam Squad', 'Design Team', 'Gym Crew'];

  EventKind _kind = EventKind.alarm;
  String? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.preselectedGroup ?? _demoGroups.first;
  }

  Widget _typeCard({
    required EventKind kind,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _kind == kind;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _kind = kind),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.light1 : AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('New Event')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type', style: textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _typeCard(
                    kind: EventKind.alarm,
                    icon: Icons.alarm_rounded,
                    title: 'Alarm',
                    subtitle: 'Hard task, strict wake-up',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _typeCard(
                    kind: EventKind.reminder,
                    icon: Icons.notifications_rounded,
                    title: 'Reminder',
                    subtitle: 'Soft task, acknowledgment',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Group', style: textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _selectedGroup,
                items: _demoGroups
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedGroup = v),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Next',
                onPressed: _selectedGroup != null
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EventTimeSetupScreen(
                              draft: EventDraft(groupName: _selectedGroup!, kind: _kind),
                            ),
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

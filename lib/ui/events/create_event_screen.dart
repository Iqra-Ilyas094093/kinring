import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
import '../../models/group_model.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/event_card.dart';
import 'event_time_setup_screen.dart';

/// Create Event screen (product doc 5.7.1). Type selector (Alarm vs
/// Reminder, two large cards) + group selector, then into Time & Repeat
/// Setup.
///
/// Group list is live via [GroupsViewModel.listenGroups] — picks from
/// groups the current user is actually in, not a demo list.
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key, this.preselectedGroupId});

  final String? preselectedGroupId;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  EventKind _kind = EventKind.alarm;
  Group? _selectedGroup;

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
              StreamBuilder<List<Group>>(
                stream: context.read<GroupsViewModel>().listenGroups(),
                builder: (context, snap) {
                  final groups = snap.data ?? const <Group>[];

                  if (snap.connectionState == ConnectionState.waiting && groups.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: LinearProgressIndicator(color: AppColors.primary),
                    );
                  }
                  if (groups.isEmpty) {
                    return Text(
                      "You're not in any groups yet — create or join one first.",
                      style: textTheme.bodyMedium,
                    );
                  }

                  _selectedGroup ??= groups.firstWhere(
                    (g) => g.id == widget.preselectedGroupId,
                    orElse: () => groups.first,
                  );
                  // Keep selection valid if the picked group disappears
                  // (e.g. left/deleted) while this screen is open.
                  if (!groups.any((g) => g.id == _selectedGroup!.id)) {
                    _selectedGroup = groups.first;
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedGroup!.id,
                    items: groups
                        .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                        .toList(),
                    onChanged: (id) => setState(
                      () => _selectedGroup = groups.firstWhere((g) => g.id == id),
                    ),
                  );
                },
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Next',
                onPressed: _selectedGroup != null
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EventTimeSetupScreen(
                              draft: EventDraft(
                                groupId: _selectedGroup!.id,
                                groupName: _selectedGroup!.name,
                                kind: _kind,
                              ),
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

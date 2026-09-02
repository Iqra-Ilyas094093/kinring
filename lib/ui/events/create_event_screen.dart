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
/// Live data: [GroupsViewModel.listenGroups] backs the group dropdown.
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key, this.preselectedGroupId});

  final String? preselectedGroupId;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  EventKind _kind = EventKind.alarm;
  String? _selectedGroupId;

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
    final groupsVm = context.read<GroupsViewModel>();

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
              StreamBuilder<List<GroupModel>>(
                stream: groupsVm.listenGroups(),
                builder: (context, snapshot) {
                  final groups = snapshot.data ?? const <GroupModel>[];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  if (groups.isEmpty) {
                    return Text(
                      'Join or create a group first to schedule an event.',
                      style: textTheme.bodySmall,
                    );
                  }
                  _selectedGroupId ??= widget.preselectedGroupId ?? groups.first.id;
                  if (!groups.any((g) => g.id == _selectedGroupId)) {
                    _selectedGroupId = groups.first.id;
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedGroupId,
                    items: groups
                        .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedGroupId = v),
                  );
                },
              ),
              const Spacer(),
              StreamBuilder<List<GroupModel>>(
                stream: groupsVm.listenGroups(),
                builder: (context, snapshot) {
                  final groups = snapshot.data ?? const <GroupModel>[];
                  final selected = groups.where((g) => g.id == _selectedGroupId).toList();
                  return PrimaryButton(
                    label: 'Next',
                    onPressed: selected.isNotEmpty
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EventTimeSetupScreen(
                                  draft: EventDraft(
                                    groupId: selected.first.id,
                                    groupName: selected.first.name,
                                    kind: _kind,
                                  ),
                                ),
                              ),
                            )
                        : null,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/services/event_trigger.dart';
import '../../models/event_draft.dart';
import '../../viewmodels/events_viewmodel.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/secondary_button.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/common/status_badge.dart';
import 'edit_event_screen.dart';

/// Upcoming Event Detail screen (product doc 5.7.5). Event info card,
/// per-member status list, and a Cancel Event action for the admin/
/// creator.
///
/// Cancel Event is wired to [EventsViewModel.cancelEvent] (Phase 3).
///
/// TODO(Phase 8): `_isCreatorOrAdmin` and `_demoParticipants` should
/// come from an EventsViewModel/GroupsViewModel lookup and the
/// `statuses` subcollection — participant statuses go live once the
/// Task Clear flow (Phase 8) writes them.
class UpcomingEventDetailScreen extends StatelessWidget {
  const UpcomingEventDetailScreen({super.key, required this.draft});

  final EventDraft draft;

  static const _isCreatorOrAdmin = true;
  static const _demoParticipants = [
    (name: 'Alex Rivera', status: EventMemberStatus.pending),
    (name: 'Sam Chen', status: EventMemberStatus.pending),
    (name: 'Priya Nair', status: EventMemberStatus.pending),
    (name: 'Jon Kim', status: EventMemberStatus.pending),
  ];

  Future<void> _cancelEvent(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Cancel Event',
      message: 'This will remove the event for all members.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed && draft.isPersisted) {
      await context.read<EventsViewModel>().cancelEvent(draft.groupId!, draft.id!);
      if (!context.mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = draft.title.trim().isEmpty
        ? (draft.kind == EventKind.alarm ? 'Alarm' : 'Reminder')
        : draft.title.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_isCreatorOrAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.dark1),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EditEventScreen(draft: draft)),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(draft.groupName, style: textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${draft.dateLabel} · ${draft.timeLabel}', style: textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Repeats: ${draft.repeatLabel}', style: textTheme.bodySmall),
                  Text('Task: ${draft.taskLabel}', style: textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Participants', style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            for (final p in _demoParticipants)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    AppAvatar(name: p.name, size: 36),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(p.name, style: textTheme.bodyLarge)),
                    StatusBadge(status: p.status),
                  ],
                ),
              ),
            if (_isCreatorOrAdmin) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Cancel Event',
                onPressed: () => _cancelEvent(context),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            // TODO(backend wiring): remove once AlarmManager/FCM actually
            // fire EventTrigger.fire — this button exists purely so the
            // Ringing/Task UI is reachable and testable before that lands.
            SecondaryButton(
              label: 'Preview: Trigger This Event',
              onPressed: () => EventTrigger.fire(context, draft),
            ),
          ],
        ),
      ),
    );
  }
}

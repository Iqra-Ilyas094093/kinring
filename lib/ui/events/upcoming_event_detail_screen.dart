import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/services/event_trigger.dart';
import '../../models/event_draft.dart';
import '../../models/group_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/events_viewmodel.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/secondary_button.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/common/status_badge.dart';
import 'edit_event_screen.dart';

/// Upcoming Event Detail screen (product doc 5.7.5). Event info card,
/// per-member roster, and a Cancel Event action for the admin/creator.
///
/// Live data: [GroupsViewModel.listenMembers] for the roster and
/// [EventsViewModel.cancelEvent] for cancel. Every member shows
/// "Pending" — real cleared/ringing/snoozed status needs the `statuses`
/// subcollection from Phase 8 (Part 11), not built yet.
class UpcomingEventDetailScreen extends StatelessWidget {
  const UpcomingEventDetailScreen({super.key, required this.draft});

  final EventDraft draft;

  Future<void> _cancelEvent(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Cancel Event',
      message: 'This will remove the event for all members.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      if (draft.eventId != null && draft.groupId.isNotEmpty) {
        await context.read<EventsViewModel>().cancelEvent(draft.groupId, draft.eventId!);
      }
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = draft.title.trim().isEmpty
        ? (draft.kind == EventKind.alarm ? 'Alarm' : 'Reminder')
        : draft.title.trim();
    final groupsVm = context.read<GroupsViewModel>();
    final myUid = context.read<AuthViewModel>().currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: StreamBuilder<List<GroupMemberModel>>(
          stream: draft.groupId.isEmpty
              ? const Stream<List<GroupMemberModel>>.empty()
              : groupsVm.listenMembers(draft.groupId),
          builder: (context, memberSnap) {
            final members = memberSnap.data ?? const <GroupMemberModel>[];
            final isCreatorOrAdmin = members.any((m) => m.uid == myUid && m.isAdmin);

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
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
                    ),
                    if (isCreatorOrAdmin)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.dark1),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => EditEventScreen(draft: draft)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Participants', style: textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                for (final member in members)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        AppAvatar(name: member.displayName ?? 'Member', imageUrl: member.photoUrl, size: 36),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: Text(member.displayName ?? 'Member', style: textTheme.bodyLarge)),
                        const StatusBadge(status: EventMemberStatus.pending),
                      ],
                    ),
                  ),
                if (isCreatorOrAdmin) ...[
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Cancel Event',
                    onPressed: () => _cancelEvent(context),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                // TODO(Phase 4): remove once AlarmManager/FCM actually fire
                // EventTrigger.fire — this button exists purely so the
                // Ringing/Task UI is reachable and testable before that lands.
                SecondaryButton(
                  label: 'Preview: Trigger This Event',
                  onPressed: () => EventTrigger.fire(context, draft),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

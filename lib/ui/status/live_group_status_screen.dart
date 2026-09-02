import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
import '../../models/group_model.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/countdown_text.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/common/status_badge.dart';

/// Live Group Status Screen (product doc 5.9.1). Live elapsed-time
/// counter since the event fired, and a member list with color-coded
/// status badges.
///
/// Live data: [GroupsViewModel.listenMembers] for the real roster. Every
/// member shows "Pending" — live cleared/ringing/snoozed badges and the
/// auto-navigate-when-all-cleared behavior both need the `statuses`
/// subcollection from Phase 8 (Part 11), not built yet (you're through
/// Phase 6). Wire an EventStatusViewModel reading
/// `groups/{id}/events/{id}/statuses` next to close this out.
class LiveGroupStatusScreen extends StatelessWidget {
  LiveGroupStatusScreen({super.key, required this.draft, DateTime? startedAt})
      : startedAt = startedAt ?? DateTime.now();

  final EventDraft draft;
  final DateTime startedAt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = draft.title.trim().isEmpty
        ? (draft.kind == EventKind.alarm ? 'Alarm' : 'Reminder')
        : draft.title.trim();
    final groupsVm = context.read<GroupsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(draft.groupName, style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Text('Elapsed', style: textTheme.bodySmall),
                  const SizedBox(width: AppSpacing.sm),
                  CountdownText(startTime: startedAt, style: textTheme.headlineMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(color: AppColors.border),
              Expanded(
                child: draft.groupId.isEmpty
                    ? const SizedBox.shrink()
                    : StreamBuilder<List<GroupMemberModel>>(
                        stream: groupsVm.listenMembers(draft.groupId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final members = snapshot.data ?? const <GroupMemberModel>[];
                          return ListView.separated(
                            itemCount: members.length,
                            separatorBuilder: (_, __) => const Divider(color: AppColors.border),
                            itemBuilder: (context, i) {
                              final member = members[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                child: Row(
                                  children: [
                                    AppAvatar(name: member.displayName ?? 'Member', imageUrl: member.photoUrl, size: 40),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(member.displayName ?? 'Member', style: textTheme.bodyLarge),
                                    ),
                                    const StatusBadge(status: EventMemberStatus.pending),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

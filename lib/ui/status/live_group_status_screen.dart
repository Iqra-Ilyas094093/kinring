import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/countdown_text.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/common/status_badge.dart';

/// Live Group Status Screen (product doc 5.9.1). Live elapsed-time
/// counter since the event fired, and a member list with color-coded
/// status badges that update in real time. Reached from: the Ringing/
/// Task flow once a member clears their task, or from Admin Panel's
/// "Ring Now".
///
/// TODO: replace the demo timer/list with a live Firestore listener via
/// an EventStatusViewModel; auto-navigate back to Home once every member
/// shows `cleared` (per doc: "auto-navigates back to Home once all
/// members have cleared").
class LiveGroupStatusScreen extends StatelessWidget {
  LiveGroupStatusScreen({super.key, required this.draft, DateTime? startedAt})
      : startedAt = startedAt ?? DateTime.now();

  final EventDraft draft;
  final DateTime startedAt;

  static const _demoParticipants = [
    (name: 'Alex Rivera', status: EventMemberStatus.cleared),
    (name: 'Sam Chen', status: EventMemberStatus.ringing),
    (name: 'Priya Nair', status: EventMemberStatus.snoozed),
    (name: 'Jon Kim', status: EventMemberStatus.pending),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = draft.title.trim().isEmpty
        ? (draft.kind == EventKind.alarm ? 'Alarm' : 'Reminder')
        : draft.title.trim();
    final clearedCount = _demoParticipants.where((p) => p.status == EventMemberStatus.cleared).length;

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
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$clearedCount of ${_demoParticipants.length} cleared',
                style: textTheme.bodySmall?.copyWith(color: AppColors.headingPurple),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(color: AppColors.border),
              Expanded(
                child: ListView.separated(
                  itemCount: _demoParticipants.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.border),
                  itemBuilder: (context, i) {
                    final p = _demoParticipants[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          AppAvatar(name: p.name, size: 40),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Text(p.name, style: textTheme.bodyLarge)),
                          StatusBadge(status: p.status),
                        ],
                      ),
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

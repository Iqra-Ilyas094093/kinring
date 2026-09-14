import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
import '../../models/event_status_model.dart';
import '../../models/group_model.dart';
import '../../viewmodels/event_status_viewmodel.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/countdown_text.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/common/status_badge.dart';
import '../core_navigation/core_navigation_screen.dart';

/// Live Group Status Screen (product doc 5.9.1). Live elapsed-time
/// counter since the event fired, and a member list with color-coded
/// status badges.
///
/// Phase 8: [EventStatusViewModel.listenStatuses] is merged against
/// [GroupsViewModel.listenMembers] here — a member with no status doc
/// yet is "Pending", one with a `cleared` doc is "Cleared". Auto-
/// navigates back to Home once every active member has cleared, per
/// the doc's own note on this screen. Ad-hoc "Ring Now" broadcasts
/// (Phase 7) have no `eventId`/backing event doc, so every member just
/// shows "Pending" for those — there's nothing to listen to and no
/// group-clear condition to auto-navigate on.
class LiveGroupStatusScreen extends StatefulWidget {
  LiveGroupStatusScreen({super.key, required this.draft, DateTime? startedAt})
      : startedAt = startedAt ?? DateTime.now();

  final EventDraft draft;
  final DateTime startedAt;

  @override
  State<LiveGroupStatusScreen> createState() => _LiveGroupStatusScreenState();
}

class _LiveGroupStatusScreenState extends State<LiveGroupStatusScreen> {
  final _statusVm = EventStatusViewModel();
  bool _navigated = false;

  void _maybeAutoNavigateHome(List<GroupMemberModel> members, List<EventStatusModel> statuses) {
    if (_navigated || members.isEmpty) return;
    final clearedUids = statuses
        .where((s) => s.status == EventMemberStatus.cleared)
        .map((s) => s.uid)
        .toSet();
    final allCleared = members.every((m) => clearedUids.contains(m.uid));
    if (!allCleared) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CoreNavigationScreen()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = widget.draft.title.trim().isEmpty
        ? (widget.draft.kind == EventKind.alarm ? 'Alarm' : 'Reminder')
        : widget.draft.title.trim();
    final groupsVm = context.read<GroupsViewModel>();
    final eventId = widget.draft.eventId;
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.draft.groupName, style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Text('Elapsed', style: textTheme.bodySmall),
                  const SizedBox(width: AppSpacing.sm),
                  CountdownText(startTime: widget.startedAt, style: textTheme.headlineMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(color: AppColors.border),
              Expanded(
                child: widget.draft.groupId.isEmpty
                    ? const SizedBox.shrink()
                    : StreamBuilder<List<GroupMemberModel>>(
                        stream: groupsVm.listenMembers(widget.draft.groupId),
                        builder: (context, memberSnap) {
                          if (memberSnap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final members = memberSnap.data ?? const <GroupMemberModel>[];
                          final isAdmin = members.any((m) => m.uid == myUid && m.isAdmin);

                          if (eventId == null) {
                            return _MemberList(
                              members: members,
                              statusByUid: const {},
                              isAdmin: false,
                              groupId: widget.draft.groupId,
                              eventId: null,
                              statusVm: _statusVm,
                            );
                          }

                          return StreamBuilder<List<EventStatusModel>>(
                            stream: _statusVm.listenStatuses(groupId: widget.draft.groupId, eventId: eventId),
                            builder: (context, statusSnap) {
                              final statuses = statusSnap.data ?? const <EventStatusModel>[];
                              _maybeAutoNavigateHome(members, statuses);
                              final statusByUid = {for (final s in statuses) s.uid: s};
                              return _MemberList(
                                members: members,
                                statusByUid: statusByUid,
                                isAdmin: isAdmin,
                                groupId: widget.draft.groupId,
                                eventId: eventId,
                                statusVm: _statusVm,
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

class _MemberList extends StatefulWidget {
  const _MemberList({
    required this.members,
    required this.statusByUid,
    required this.isAdmin,
    required this.groupId,
    required this.eventId,
    required this.statusVm,
  });

  final List<GroupMemberModel> members;
  final Map<String, EventStatusModel> statusByUid;
  final bool isAdmin;
  final String groupId;
  final String? eventId;
  final EventStatusViewModel statusVm;

  @override
  State<_MemberList> createState() => _MemberListState();
}

class _MemberListState extends State<_MemberList> {
  static const _forceStopGate = Duration(seconds: 30);
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _confirmAndForceStop(GroupMemberModel member) async {
    final eventId = widget.eventId;
    if (eventId == null) return;
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Force stop alarm?',
      message:
          "This immediately silences ${member.displayName ?? 'this member'}'s alarm on their device, even though they haven't cleared it themselves.",
      confirmLabel: 'Force Stop',
    );
    if (!confirmed) return;
    await widget.statusVm.forceStop(
      groupId: widget.groupId,
      eventId: eventId,
      targetUid: member.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView.separated(
      itemCount: widget.members.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.border),
      itemBuilder: (context, i) {
        final member = widget.members[i];
        final statusModel = widget.statusByUid[member.uid];
        final status = statusModel?.status ?? EventMemberStatus.pending;

        final ringingLongEnough = status == EventMemberStatus.ringing &&
            statusModel?.ringingAt != null &&
            DateTime.now().difference(statusModel!.ringingAt!) >= _forceStopGate;
        final canForceStop = widget.isAdmin && ringingLongEnough;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              AppAvatar(name: member.displayName ?? 'Member', imageUrl: member.photoUrl, size: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(member.displayName ?? 'Member', style: textTheme.bodyLarge),
              ),
              StatusBadge(status: status),
              if (canForceStop) ...[
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: () => _confirmAndForceStop(member),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Force Stop'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/services/event_trigger.dart';
import '../../models/event_draft.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/common/list_row.dart';
import '../../widgets/common/section_header.dart';
import '../groups/group_settings_screen.dart';
import '../events/edit_event_screen.dart';
import 'event_history_screen.dart';

/// Admin Panel Screen (product doc 5.9.2). The prominent "Ring Now"
/// broadcast, a quick-edit list of past/upcoming events, and a shortcut
/// into Group Settings.
///
/// TODO: replace `_demoEvents` with an EventsViewModel query scoped to
/// this group; "Ring Now" should call the Cloudflare Worker HTTP
/// endpoint described in doc Part 4 to broadcast push-only, bypassing
/// silent mode, per doc Part 3 step 6.
class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key, required this.groupId, required this.groupName});

  final String groupId;
  final String groupName;

  static const _demoEvents = [
    (title: 'Study Session', time: '6:00 AM', kind: EventKind.alarm, isPast: false),
    (title: 'Morning Check-in', time: 'Yesterday, 8:00 AM', kind: EventKind.reminder, isPast: true),
  ];

  Future<void> _ringNow(BuildContext context, int memberCount) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Ring Now',
      message: 'This will instantly alert all $memberCount members. Continue?',
      confirmLabel: 'Ring Now',
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      // TODO: POST to the Cloudflare Worker "Ring Now" endpoint (doc
      // Part 4) — push-only broadcast, bypasses silent mode. This local
      // fire is what that push ultimately triggers on each device.
      EventTrigger.fire(
        context,
        EventDraft(groupName: groupName, title: 'Ring Now Broadcast', kind: EventKind.alarm),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Admin Panel — $groupName')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _ringNow(context, 4),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                icon: const Icon(Icons.campaign_rounded, color: AppColors.white),
                label: Text(
                  'Ring Now',
                  style: textTheme.titleLarge?.copyWith(color: AppColors.white),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Instantly broadcasts to every member, bypassing silent mode.',
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(
              title: 'Events',
              trailing: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EventHistoryScreen(groupName: groupName)),
                ),
                child: const Text('View History'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final event in _demoEvents) ...[
              EventCard(
                title: event.title,
                groupName: groupName,
                timeLabel: event.time,
                kind: event.kind,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditEventScreen(
                      draft: EventDraft(
                        groupName: groupName,
                        title: event.title,
                        kind: event.kind,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.md),
            ListRow(
              label: 'Group Settings',
              leading: const Icon(Icons.settings_outlined, color: AppColors.dark1),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => GroupSettingsScreen(groupId: groupId, groupName: groupName)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

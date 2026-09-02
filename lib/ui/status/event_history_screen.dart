import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/common/empty_state.dart';

/// Event History Screen (product doc 5.9.3). Reverse-chronological list
/// of past events with a per-member clear-time summary.
///
/// NOT wired to real data: this screen needs the `statuses` subcollection
/// per event (product doc Part 11 Phase 8, "Task Clear + Live Status
/// Wire") plus a past-events query (Phase 10). Neither exists in the
/// backend yet — you're through Phase 6, and Phase 8/10 come after Phase
/// 7 (Ring Now worker). Showing an honest empty state here instead of
/// fabricated history until that lands.
class EventHistoryScreen extends StatelessWidget {
  const EventHistoryScreen({super.key, required this.groupId, required this.groupName});

  final String groupId;
  final String groupName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('History')),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: EmptyState(
              icon: Icons.history_rounded,
              title: 'History not available yet',
              subtitle:
                  'Event History needs Phase 8 (task-clear status) and Phase 10 '
                  '(history query) from the backend roadmap — build those next.',
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/common/toggle_row.dart';

/// Notification Settings screen (product doc 5.10.2). Toggle rows for
/// alarm sounds / reminder notifications / group activity, plus optional
/// volume & vibration sliders.
///
/// TODO: persist to a NotificationPreferences store instead of local state.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _alarmSounds = true;
  bool _reminderNotifications = true;
  bool _groupActivityUpdates = false;
  double _volume = 0.8;
  double _vibration = 0.6;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ToggleRow(
              label: 'Alarm sounds',
              subtitle: 'Full-screen ringing when an alarm fires',
              value: _alarmSounds,
              onChanged: (v) => setState(() => _alarmSounds = v),
            ),
            const Divider(color: AppColors.border),
            ToggleRow(
              label: 'Reminder notifications',
              subtitle: 'Notification card for soft-task reminders',
              value: _reminderNotifications,
              onChanged: (v) => setState(() => _reminderNotifications = v),
            ),
            const Divider(color: AppColors.border),
            ToggleRow(
              label: 'Group activity updates',
              subtitle: 'When members join, leave, or clear a task',
              value: _groupActivityUpdates,
              onChanged: (v) => setState(() => _groupActivityUpdates = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Volume', style: textTheme.bodyLarge),
            Slider(
              value: _volume,
              onChanged: _alarmSounds ? (v) => setState(() => _volume = v) : null,
              activeColor: AppColors.primary,
            ),
            Text('Vibration', style: textTheme.bodyLarge),
            Slider(
              value: _vibration,
              onChanged: (v) => setState(() => _vibration = v),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

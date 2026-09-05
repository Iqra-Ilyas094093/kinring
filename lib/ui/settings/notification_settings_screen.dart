import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/common/toggle_row.dart';

/// Notification Settings screen (product doc 5.10.2). Toggle rows for
/// alarm sounds / reminder notifications / group activity, plus optional
/// volume & vibration sliders.
///
/// Phase 10: persisted to `shared_preferences` (device-only, no cloud
/// needed per the doc's own note) instead of local widget state that
/// reset every time the screen reopened.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  static const _kAlarmSounds = 'notif_alarm_sounds';
  static const _kReminderNotifications = 'notif_reminder_notifications';
  static const _kGroupActivityUpdates = 'notif_group_activity_updates';
  static const _kVolume = 'notif_volume';

  bool _loaded = false;
  bool _alarmSounds = true;
  bool _reminderNotifications = true;
  // Defaults to ON — this was OFF before, which meant kinring-notify's
  // pushes (member joined / event created / profile updated) never
  // showed a heads-up out of the box even though the Firestore record
  // (and the Notifications screen list) worked fine, since that part
  // doesn't go through this gate at all. A toggle that silently starts
  // OFF for a feature the person hasn't touched yet reads as "push
  // notifications are broken" — better to default to on and let people
  // opt out.
  bool _groupActivityUpdates = true;
  double _volume = 0.8;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _alarmSounds = prefs.getBool(_kAlarmSounds) ?? true;
      _reminderNotifications = prefs.getBool(_kReminderNotifications) ?? true;
      _groupActivityUpdates = prefs.getBool(_kGroupActivityUpdates) ?? true;
      _volume = prefs.getDouble(_kVolume) ?? 0.8;
      _loaded = true;
    });
  }

  Future<void> _setBool(String key, bool value, void Function(bool) apply) async {
    setState(() => apply(value));
    (await SharedPreferences.getInstance()).setBool(key, value);
  }

  Future<void> _setDouble(String key, double value, void Function(double) apply) async {
    setState(() => apply(value));
    (await SharedPreferences.getInstance()).setDouble(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              onChanged: (v) => _setBool(_kAlarmSounds, v, (x) => _alarmSounds = x),
            ),
            const Divider(color: AppColors.border),
            ToggleRow(
              label: 'Reminder notifications',
              subtitle: 'Notification card for soft-task reminders',
              value: _reminderNotifications,
              onChanged: (v) => _setBool(_kReminderNotifications, v, (x) => _reminderNotifications = x),
            ),
            const Divider(color: AppColors.border),
            ToggleRow(
              label: 'Group activity updates',
              subtitle: 'When members join, leave, or clear a task',
              value: _groupActivityUpdates,
              onChanged: (v) => _setBool(_kGroupActivityUpdates, v, (x) => _groupActivityUpdates = x),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Volume', style: textTheme.bodyLarge),
            Text(
              'Whether the alarm plays sound at all — Android ties '
              "sound to a fixed channel, so this switches between a "
              'sound channel and a silent-but-still-vibrating one, '
              "rather than a real continuous level.",
              style: textTheme.bodySmall,
            ),
            Slider(
              value: _volume,
              onChanged: _alarmSounds ? (v) => _setDouble(_kVolume, v, (x) => _volume = x) : null,
              activeColor: AppColors.primary,
            ),
            // No separate Vibration slider — Android notification
            // channels can't have their vibration toggled per-call any
            // more than sound can (see LocalNotificationsService), and
            // an alarm should always be felt at minimum, so both alarm
            // channels (sound and silent) vibrate unconditionally.
          ],
        ),
      ),
    );
  }
}

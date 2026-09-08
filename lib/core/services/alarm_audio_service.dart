import 'dart:developer' as developer;

import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

/// Custom sound (alarm) + custom vibration (reminder), played directly by
/// app code instead of the OS notification-channel sound/vibrate.
///
/// Why: `AndroidNotificationChannel(playSound: true)` ties audio to the
/// phone's NOTIFICATION volume slider — often low/muted/DND'd — and
/// channels are immutable once created (v1→v2→v3 churn every time this
/// needed a tweak). Playing the file ourselves via `audioplayers` on the
/// ALARM audio stream (`AndroidAudioContentType.sonification` +
/// `AndroidAudioUsage.alarm`) rings through DND/silent mode the same way
/// a real alarm clock does, with zero channel-versioning games.
///
/// Called from both the local `AlarmScheduler` background isolate AND
/// the FCM background isolate — no special per-isolate init needed here
/// (unlike `LocalNotificationsService`, which needs
/// `ensureReadyInBackgroundIsolate`); `AudioPlayer()` and the `vibration`
/// plugin both work as soon as constructed/called.
class AlarmAudioService {
  AlarmAudioService._();

  static final AudioPlayer _player = AudioPlayer();

  /// File lives at `assets/sounds/alarm_sound.mp3` — must be declared
  /// under `flutter: assets:` in pubspec.yaml (already added) AND
  /// physically present on disk, or [playAlarmSound] fails at the
  /// `.play()` call below (previously failing silently — now logged).
  static const _alarmAssetPath = 'sounds/alarm_sound.mp3';

  /// Starts the alarm sound, looping, on the ALARM stream. Safe to call
  /// even if a previous alarm's sound never got stopped (e.g. app was
  /// killed mid-ring) — `stop()` first clears any stale state.
  ///
  /// Wrapped in try/catch with `developer.log` — this call runs inside a
  /// background isolate (no debugger attached, no UI to show an error
  /// dialog), so a thrown exception here previously just vanished with
  /// no visible sign anything went wrong. Now it shows up in
  /// `flutter logs` / `adb logcat` under tag `AlarmAudioService`.
  static Future<void> playAlarmSound() async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      // Simplified context: usageType alone is enough to route to the
      // ALARM stream; the earlier sonification+gainTransient combo is
      // an unusual pairing for a *looping* sound (gainTransient implies
      // a brief, self-releasing sound — technically wrong for something
      // meant to keep ringing) and may have been silently rejected by
      // some OEM audio stacks.
      await _player.setAudioContext(
         AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
      await _player.setVolume(1.0);
      await _player.play(AssetSource(_alarmAssetPath));
      developer.log('alarm sound started', name: 'AlarmAudioService');
    } catch (e, st) {
      developer.log(
        'FAILED to play alarm sound: $e',
        name: 'AlarmAudioService',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Called from [LocalNotificationsService.dismiss] — task cleared,
  /// snoozed, or the ringing screen closed some other way.
  static Future<void> stopAlarmSound() async {
    try {
      await _player.stop();
    } catch (e) {
      developer.log('stopAlarmSound error: $e', name: 'AlarmAudioService');
    }
  }

  /// Reminder's own vibration pattern (distinct feel from the alarm's
  /// continuous ring) — short double-buzz, not a system default.
  /// `hasVibrator()` guards devices/emulators with no vibration motor.
  static Future<void> vibrateReminder() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(pattern: [0, 250, 150, 250]);
      } else {
        developer.log('device reports no vibrator', name: 'AlarmAudioService');
      }
    } catch (e) {
      developer.log('vibrateReminder error: $e', name: 'AlarmAudioService');
    }
  }
}
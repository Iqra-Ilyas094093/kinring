import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

/// Custom sounds (alarm) + custom vibration (reminder), played directly by
/// app code instead of the OS notification-channel sounds/vibrate.
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

  /// File lives at `android/app/src/main/res/raw/alarm_sound.mp3` — add
  /// it there manually (any short loop-able alarm tone). Referenced here
  /// as an asset copy under `assets/sounds/` instead so iOS (future) and
  /// the same file work identically; see pubspec.yaml `assets:` entry.
  static const _alarmAssetPath = 'sounds/alarm_sound.mp3';

  /// Starts the alarm sounds, looping, on the ALARM stream. Safe to call
  /// even if a previous alarm's sounds never got stopped (e.g. app was
  /// killed mid-ring) — `stop()` first clears any stale state.
  static Future<void> playAlarmSound() async {
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransient,
        ),
      ),
    );
    await _player.play(AssetSource(_alarmAssetPath));
  }

  /// Called from [LocalNotificationsService.dismiss] — task cleared,
  /// snoozed, or the ringing screen closed some other way.
  static Future<void> stopAlarmSound() async {
    await _player.stop();
  }

  /// Reminder's own vibration pattern (distinct feel from the alarm's
  /// continuous ring) — short double-buzz, not a system default.
  /// `hasVibrator()` guards devices/emulators with no vibration motor.
  static Future<void> vibrateReminder() async {
    if (await Vibration.hasVibrator() ?? false) {
      await Vibration.vibrate(pattern: [0, 250, 150, 250]);
    }
  }
}
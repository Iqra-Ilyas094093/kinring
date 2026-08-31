import '../widgets/common/event_card.dart';

enum RepeatRule { once, daily, weekly, custom }

/// In-progress state for the Create/Edit Event flow (product doc 5.7).
/// Carried forward screen-to-screen as a constructor argument — mirrors
/// how the auth flow passes `email` between Forgot Password and Reset
/// Link Sent. Becomes a real Firestore-backed model once the Group/Event
/// backend exists.
class EventDraft {
  EventDraft({
    required this.groupName,
    this.kind = EventKind.alarm,
    this.title = '',
    this.date,
    this.time,
    this.repeatRule = RepeatRule.once,
    this.customDays = const <String>{},
    this.snoozeEnabled = true,
    this.confirmationPhrase = '',
    this.useSimpleTap = true,
  });

  final String groupName;
  EventKind kind;
  String title;
  DateTime? date;
  DateTime? time;
  RepeatRule repeatRule;
  Set<String> customDays;
  bool snoozeEnabled;
  String confirmationPhrase;
  bool useSimpleTap;

  String get repeatLabel => switch (repeatRule) {
        RepeatRule.once => 'Once',
        RepeatRule.daily => 'Daily',
        RepeatRule.weekly => 'Weekly',
        RepeatRule.custom => 'Custom (${customDays.join(', ')})',
      };

  String get timeLabel {
    if (time == null) return 'Not set';
    final h = time!.hour % 12 == 0 ? 12 : time!.hour % 12;
    final m = time!.minute.toString().padLeft(2, '0');
    final period = time!.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String get dateLabel {
    if (date == null) return 'Not set';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date!.month - 1]} ${date!.day}, ${date!.year}';
  }

  String get taskLabel => kind == EventKind.alarm
      ? 'Color Match'
      : (useSimpleTap ? 'Tap to confirm' : '"$confirmationPhrase"');
}

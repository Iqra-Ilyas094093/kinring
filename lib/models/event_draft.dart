import '../widgets/common/event_card.dart';

enum RepeatRule { once, daily, weekly, custom }

/// In-progress state for the Create/Edit Event flow (product doc 5.7).
/// Carried forward screen-to-screen as a constructor argument — mirrors
/// how the auth flow passes `email` between Forgot Password and Reset
/// Link Sent.
///
/// [groupId]/[id] are null while a brand-new event is still being built
/// (Create Event flow, before Confirm & Create); [EventsViewModel]
/// requires [groupId] to write. Once loaded from Firestore for Edit/
/// Detail screens, both are set — see [EventDraft.fromFirestore].
class EventDraft {
  EventDraft({
    this.id,
    this.groupId,
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

  /// Firestore doc-conversion constructor, kept here (not in
  /// `event_model.dart`) so `EventDraft` never imports the Firestore
  /// model — avoids a circular import (`event_model.dart` already
  /// imports this file for `RepeatRule`/`EventKind`).
  factory EventDraft.fromFirestore({
    required String id,
    required String groupId,
    required String groupName,
    required EventKind kind,
    required String title,
    required DateTime localTime,
    required RepeatRule repeatRule,
    Set<String> customDays = const <String>{},
    bool snoozeEnabled = true,
    String confirmationPhrase = '',
    bool useSimpleTap = true,
  }) =>
      EventDraft(
        id: id,
        groupId: groupId,
        groupName: groupName,
        kind: kind,
        title: title,
        date: localTime,
        time: localTime,
        repeatRule: repeatRule,
        customDays: customDays,
        snoozeEnabled: snoozeEnabled,
        confirmationPhrase: confirmationPhrase,
        useSimpleTap: useSimpleTap,
      );

  /// Null until Confirm & Create writes the Firestore doc, or until
  /// loaded from one (Edit/Detail screens).
  final String? id;
  final String? groupId;
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

  /// True once this draft is backed by a real Firestore doc — Cancel/
  /// Save Changes need this, a new in-progress draft has neither yet.
  bool get isPersisted => id != null && groupId != null;

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

  /// Combines [date] + [time] into one local `DateTime`, converted to
  /// UTC for the `timeUTC` Firestore field. Falls back to now if either
  /// piece is missing (shouldn't happen past Time & Repeat Setup, whose
  /// "Next" button is gated on both being set).
  DateTime toUtcDateTime() {
    final d = date ?? DateTime.now();
    final t = time ?? DateTime.now();
    return DateTime(d.year, d.month, d.day, t.hour, t.minute).toUtc();
  }
}

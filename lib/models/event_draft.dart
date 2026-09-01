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
    this.groupId = '',
    this.eventId,
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

  /// `groups/{groupId}` this event belongs (or will belong) to. Defaults
  /// to '' for the demo/preview screens that don't yet pull from
  /// GroupsViewModel — required (non-empty) once `EventsViewModel.
  /// createEvent`/`AlarmScheduler` actually run.
  final String groupId;

  /// `groups/{groupId}/events/{eventId}` once persisted. Null while the
  /// draft is still being built in the Create Event flow.
  String? eventId;

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

  /// Minimal fields needed to redraw the Ringing/Task flow (doc 5.8)
  /// from a fired alarm — passed as the `AndroidAlarmManager` callback
  /// param and as the alarm notification payload, both of which cross
  /// an isolate/platform-channel boundary and only carry primitives, so
  /// this stays a flat `Map<String, dynamic>` rather than the full
  /// draft object.
  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'eventId': eventId,
        'groupName': groupName,
        'kind': kind.name,
        'title': title,
        'repeatRule': repeatRule.name,
        'customDays': customDays.toList(),
        'snoozeEnabled': snoozeEnabled,
        'confirmationPhrase': confirmationPhrase,
        'useSimpleTap': useSimpleTap,
      };

  factory EventDraft.fromJson(Map<String, dynamic> json) => EventDraft(
        groupId: json['groupId'] as String? ?? '',
        eventId: json['eventId'] as String?,
        groupName: json['groupName'] as String? ?? '',
        kind: (json['kind'] as String? ?? 'alarm') == 'alarm' ? EventKind.alarm : EventKind.reminder,
        title: json['title'] as String? ?? '',
        repeatRule: RepeatRule.values.firstWhere(
          (r) => r.name == (json['repeatRule'] as String? ?? 'once'),
          orElse: () => RepeatRule.once,
        ),
        customDays: Set<String>.from(json['customDays'] as List? ?? const []),
        snoozeEnabled: json['snoozeEnabled'] as bool? ?? true,
        confirmationPhrase: json['confirmationPhrase'] as String? ?? '',
        useSimpleTap: json['useSimpleTap'] as bool? ?? true,
      );
}

import '../../models/event_draft.dart';

/// Pure date-math for turning `(timeOfDay, repeatRule, customDays)` into
/// the next concrete `DateTime` an alarm should fire at. Kept separate
/// from [AlarmScheduler] so it's trivially unit-testable without any
/// platform-channel dependency.
class RepeatSchedule {
  RepeatSchedule._();

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// First fire time at/after [from] (defaults to now) for the given
  /// [hour]/[minute] and [repeatRule]. For `once`, this is just the next
  /// (or same-day-if-still-ahead) occurrence of that wall-clock time —
  /// the caller is expected to pass the event's actual scheduled date
  /// for `once` events; for `daily`/`weekly`/`custom` the exact date
  /// doesn't matter, only the recurring time-of-day (+ weekday for
  /// weekly/custom) does.
  static DateTime firstOccurrence({
    required DateTime baseDate,
    required int hour,
    required int minute,
    required RepeatRule repeatRule,
    required Set<String> customDays,
    DateTime? from,
  }) {
    final now = from ?? DateTime.now();

    if (repeatRule == RepeatRule.once) {
      final at = DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
      return at.isAfter(now) ? at : now.add(const Duration(seconds: 5));
    }

    if (repeatRule == RepeatRule.daily) {
      var candidate = DateTime(now.year, now.month, now.day, hour, minute);
      if (!candidate.isAfter(now)) candidate = candidate.add(const Duration(days: 1));
      return candidate;
    }

    // weekly (uses baseDate's weekday) or custom (uses customDays set).
    final targetWeekdays = repeatRule == RepeatRule.weekly
        ? {_dayNames[baseDate.weekday - 1]}
        : (customDays.isEmpty ? {_dayNames[baseDate.weekday - 1]} : customDays);

    for (var i = 0; i < 8; i++) {
      final candidateDate = DateTime(now.year, now.month, now.day, hour, minute).add(Duration(days: i));
      final dayName = _dayNames[candidateDate.weekday - 1];
      if (targetWeekdays.contains(dayName) && candidateDate.isAfter(now)) {
        return candidateDate;
      }
    }
    // Fallback — shouldn't hit given the 8-day sweep above always covers
    // a full week + today.
    return DateTime(now.year, now.month, now.day, hour, minute).add(const Duration(days: 7));
  }

  /// Next occurrence strictly after a fire that just happened at
  /// [firedAt]. `once` returns null (no reschedule).
  static DateTime? nextAfterFire({
    required DateTime firedAt,
    required RepeatRule repeatRule,
    required Set<String> customDays,
  }) {
    if (repeatRule == RepeatRule.once) return null;
    return firstOccurrence(
      baseDate: firedAt,
      hour: firedAt.hour,
      minute: firedAt.minute,
      repeatRule: repeatRule,
      customDays: customDays,
      from: firedAt.add(const Duration(minutes: 1)),
    );
  }
}

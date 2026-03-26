import 'package:quebrando_metas/features/goals/domain/focus_session.dart';

class FocusStreakCalculator {
  const FocusStreakCalculator._();

  static int currentStreakFromSessions(
    Iterable<FocusSession> sessions, {
    DateTime? now,
    int minimumSessionMinutes = FocusSession.streakMinimumMinutes,
  }) {
    final Iterable<DateTime> startDates = sessions
        .where(
          (session) =>
              session.qualifiesForStreak(minimumMinutes: minimumSessionMinutes),
        )
        .map((session) => session.startedAt);
    return currentStreakFromDates(startDates, now: now);
  }

  static int bestStreakFromSessions(
    Iterable<FocusSession> sessions, {
    int minimumSessionMinutes = FocusSession.streakMinimumMinutes,
  }) {
    final Iterable<DateTime> startDates = sessions
        .where(
          (session) =>
              session.qualifiesForStreak(minimumMinutes: minimumSessionMinutes),
        )
        .map((session) => session.startedAt);
    return bestStreakFromDates(startDates);
  }

  static int currentStreakFromDates(
    Iterable<DateTime> startDates, {
    DateTime? now,
  }) {
    final Set<DateTime> uniqueDays = startDates.map(_toLocalDay).toSet();
    if (uniqueDays.isEmpty) return 0;

    final DateTime today = _toLocalDay(now ?? DateTime.now());
    DateTime latestDay = uniqueDays.reduce(
      (current, next) => current.isAfter(next) ? current : next,
    );
    if (latestDay.isAfter(today)) {
      latestDay = today;
    }

    final int daysSinceLastStart = today.difference(latestDay).inDays;
    if (daysSinceLastStart > 1) {
      return 0;
    }

    int streak = 0;
    DateTime cursor = latestDay;
    while (uniqueDays.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int bestStreakFromDates(Iterable<DateTime> startDates) {
    final List<DateTime> sortedUniqueDays =
        startDates.map(_toLocalDay).toSet().toList()
          ..sort((a, b) => a.compareTo(b));
    if (sortedUniqueDays.isEmpty) return 0;

    int best = 1;
    int current = 1;
    for (int i = 1; i < sortedUniqueDays.length; i++) {
      final int gapInDays = sortedUniqueDays[i]
          .difference(sortedUniqueDays[i - 1])
          .inDays;
      if (gapInDays == 1) {
        current += 1;
      } else {
        current = 1;
      }
      if (current > best) {
        best = current;
      }
    }
    return best;
  }

  static DateTime _toLocalDay(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}

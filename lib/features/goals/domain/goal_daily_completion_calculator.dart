import 'package:quebrando_metas/features/goals/domain/action_day_confirmation.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';

class GoalDailyCompletionCalculator {
  const GoalDailyCompletionCalculator._();

  static bool isGoalCompletedOnDay({
    required String goalId,
    required DateTime day,
    required bool focusModeEnabled,
    Iterable<FocusSession> focusSessions = const <FocusSession>[],
    Iterable<ActionDayConfirmation> manualConfirmations =
        const <ActionDayConfirmation>[],
  }) {
    if (focusModeEnabled) {
      return hasEligibleFocusOnDay(
        goalId: goalId,
        day: day,
        focusSessions: focusSessions,
      );
    }

    return hasManualConfirmationOnDay(
      goalId: goalId,
      day: day,
      manualConfirmations: manualConfirmations,
    );
  }

  static bool hasEligibleFocusOnDay({
    required String goalId,
    required DateTime day,
    required Iterable<FocusSession> focusSessions,
    int minimumFocusMinutes = FocusSession.streakMinimumMinutes,
  }) {
    final DateTime normalizedDay = _dateOnlyLocal(day);
    for (final FocusSession session in focusSessions) {
      if (session.goalId != goalId) continue;
      if (!session.qualifiesForStreak(minimumMinutes: minimumFocusMinutes)) {
        continue;
      }
      if (_dateOnlyLocal(session.startedAt) == normalizedDay) {
        return true;
      }
    }
    return false;
  }

  static bool hasManualConfirmationOnDay({
    required String goalId,
    required DateTime day,
    required Iterable<ActionDayConfirmation> manualConfirmations,
  }) {
    final DateTime normalizedDay = _dateOnlyLocal(day);
    for (final ActionDayConfirmation confirmation in manualConfirmations) {
      if (confirmation.goalId != goalId) continue;
      if (_dateOnlyLocal(confirmation.confirmedAt) == normalizedDay) {
        return true;
      }
    }
    return false;
  }

  static bool canRegisterManualConfirmation({
    required String goalId,
    required String actionId,
    required DateTime now,
    required Iterable<ActionDayConfirmation> existingConfirmations,
  }) {
    final DateTime normalizedDay = _dateOnlyLocal(now);
    for (final ActionDayConfirmation confirmation in existingConfirmations) {
      if (confirmation.goalId != goalId) continue;
      if (confirmation.actionId != actionId) continue;
      if (_dateOnlyLocal(confirmation.confirmedAt) == normalizedDay) {
        return false;
      }
    }
    return true;
  }

  static DateTime _dateOnlyLocal(DateTime value) {
    final DateTime local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}

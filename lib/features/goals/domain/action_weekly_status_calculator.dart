import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/action_day_confirmation.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';

enum WeeklyActionDayStatus { pending, done, missed }

class ActionWeeklyStatusCalculator {
  const ActionWeeklyStatusCalculator._();

  static List<DateTime> currentWeekDays({required DateTime referenceDate}) {
    final DateTime today = _dateOnlyLocal(referenceDate);
    final int daysFromMonday = today.weekday - DateTime.monday;
    final DateTime monday = today.subtract(Duration(days: daysFromMonday));
    return List<DateTime>.generate(
      7,
      (index) => monday.add(Duration(days: index)),
      growable: false,
    );
  }

  static List<WeeklyActionDayStatus> buildWeekStatuses({
    required String goalId,
    required ActionItem action,
    required bool focusModeEnabled,
    required DateTime referenceDate,
    Iterable<FocusSession> focusSessions = const <FocusSession>[],
    Iterable<ActionDayConfirmation> manualConfirmations =
        const <ActionDayConfirmation>[],
  }) {
    final List<DateTime> weekDays = currentWeekDays(
      referenceDate: referenceDate,
    );
    return buildStatusesForDays(
      goalId: goalId,
      action: action,
      days: weekDays,
      focusModeEnabled: focusModeEnabled,
      referenceDate: referenceDate,
      focusSessions: focusSessions,
      manualConfirmations: manualConfirmations,
    );
  }

  static List<DateTime> monthDays({required int year, required int month}) {
    final DateTime firstDayOfMonth = DateTime(year, month, 1);
    final DateTime firstDayOfNextMonth = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    final int totalDays = firstDayOfNextMonth
        .difference(firstDayOfMonth)
        .inDays;
    return List<DateTime>.generate(
      totalDays,
      (index) => firstDayOfMonth.add(Duration(days: index)),
      growable: false,
    );
  }

  static List<WeeklyActionDayStatus> buildMonthStatuses({
    required String goalId,
    required ActionItem action,
    required int year,
    required int month,
    required bool focusModeEnabled,
    required DateTime referenceDate,
    Iterable<FocusSession> focusSessions = const <FocusSession>[],
    Iterable<ActionDayConfirmation> manualConfirmations =
        const <ActionDayConfirmation>[],
  }) {
    final List<DateTime> monthDaysRange = monthDays(year: year, month: month);
    return buildStatusesForDays(
      goalId: goalId,
      action: action,
      days: monthDaysRange,
      focusModeEnabled: focusModeEnabled,
      referenceDate: referenceDate,
      focusSessions: focusSessions,
      manualConfirmations: manualConfirmations,
    );
  }

  static List<WeeklyActionDayStatus> buildStatusesForDays({
    required String goalId,
    required ActionItem action,
    required Iterable<DateTime> days,
    required bool focusModeEnabled,
    required DateTime referenceDate,
    Iterable<FocusSession> focusSessions = const <FocusSession>[],
    Iterable<ActionDayConfirmation> manualConfirmations =
        const <ActionDayConfirmation>[],
  }) {
    return days
        .map(
          (day) => statusForDay(
            goalId: goalId,
            action: action,
            day: day,
            referenceDate: referenceDate,
            focusModeEnabled: focusModeEnabled,
            focusSessions: focusSessions,
            manualConfirmations: manualConfirmations,
          ),
        )
        .toList(growable: false);
  }

  static WeeklyActionDayStatus statusForDay({
    required String goalId,
    required ActionItem action,
    required DateTime day,
    required DateTime referenceDate,
    required bool focusModeEnabled,
    Iterable<FocusSession> focusSessions = const <FocusSession>[],
    Iterable<ActionDayConfirmation> manualConfirmations =
        const <ActionDayConfirmation>[],
  }) {
    final DateTime today = _dateOnlyLocal(referenceDate);
    final DateTime targetDay = _dateOnlyLocal(day);
    final bool completed = _isActionCompletedOnDay(
      goalId: goalId,
      action: action,
      day: targetDay,
      focusModeEnabled: focusModeEnabled,
      focusSessions: focusSessions,
      manualConfirmations: manualConfirmations,
    );
    if (completed) return WeeklyActionDayStatus.done;
    if (targetDay.isAfter(today) || targetDay == today) {
      return WeeklyActionDayStatus.pending;
    }
    return WeeklyActionDayStatus.missed;
  }

  static bool _isActionCompletedOnDay({
    required String goalId,
    required ActionItem action,
    required DateTime day,
    required bool focusModeEnabled,
    required Iterable<FocusSession> focusSessions,
    required Iterable<ActionDayConfirmation> manualConfirmations,
  }) {
    if (focusModeEnabled) {
      // Intencional: para evitar "resets" visuais ao alternar modo,
      // a conclusão diária no board considera qualquer fonte válida.
    }

    // A visualização semanal/mensal deve ser estável ao alternar modo foco/checklist.
    // Por isso, considera qualquer sinal de conclusão no dia.
    for (final FocusSession session in focusSessions) {
      if (session.goalId != goalId) continue;
      if (session.actionId != action.id) continue;
      if (!session.qualifiesForStreak()) continue;
      if (_dateOnlyLocal(session.startedAt) == day) {
        return true;
      }
    }

    for (final ActionDayConfirmation confirmation in manualConfirmations) {
      if (confirmation.goalId != goalId) continue;
      if (confirmation.actionId != action.id) continue;
      if (_dateOnlyLocal(confirmation.confirmedAt) == day) {
        return true;
      }
    }

    if (action.isCompleted) {
      final DateTime? completedAt = action.completedAt;
      if (completedAt == null) return false;
      return _dateOnlyLocal(completedAt) == day;
    }

    return false;
  }

  static DateTime _dateOnlyLocal(DateTime value) {
    final DateTime local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}

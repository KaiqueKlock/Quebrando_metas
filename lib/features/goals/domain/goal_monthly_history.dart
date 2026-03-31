import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/action_weekly_status_calculator.dart';

class GoalMonthlyHistory {
  const GoalMonthlyHistory({
    required this.goalId,
    required this.year,
    required this.month,
    required this.days,
    required this.rows,
  });

  final String goalId;
  final int year;
  final int month;
  final List<DateTime> days;
  final List<GoalMonthlyHistoryRow> rows;
}

class GoalMonthlyHistoryRow {
  const GoalMonthlyHistoryRow({
    required this.action,
    required this.statuses,
  });

  final ActionItem action;
  final List<WeeklyActionDayStatus> statuses;
}

class GoalMonthlyHistoryArgs {
  const GoalMonthlyHistoryArgs({
    required this.goalId,
    required this.year,
    required this.month,
    required this.focusModeEnabled,
    required this.referenceDate,
  });

  final String goalId;
  final int year;
  final int month;
  final bool focusModeEnabled;
  final DateTime referenceDate;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalMonthlyHistoryArgs &&
        other.goalId == goalId &&
        other.year == year &&
        other.month == month &&
        other.focusModeEnabled == focusModeEnabled &&
        other.referenceDate == referenceDate;
  }

  @override
  int get hashCode =>
      Object.hash(goalId, year, month, focusModeEnabled, referenceDate);
}

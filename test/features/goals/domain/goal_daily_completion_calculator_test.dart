@Tags(<String>['smoke'])
import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/action_day_confirmation.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';
import 'package:quebrando_metas/features/goals/domain/action_weekly_status_calculator.dart';
import 'package:quebrando_metas/features/goals/domain/goal_daily_completion_calculator.dart';

void main() {
  group('GoalDailyCompletionCalculator', () {
    test('focus mode marks day completed only when focus is >= 5 minutes', () {
      final DateTime day = DateTime(2026, 3, 30, 10, 0);
      final FocusSession notEligible = FocusSession(
        id: 'focus-1',
        goalId: 'goal-1',
        actionId: 'action-1',
        startedAt: day,
        endedAt: day.add(const Duration(minutes: 4)),
        durationMinutes: 30,
        status: FocusSessionStatus.completed,
        createdAt: day,
        updatedAt: day.add(const Duration(minutes: 4)),
      );
      final FocusSession eligible = FocusSession(
        id: 'focus-2',
        goalId: 'goal-1',
        actionId: 'action-2',
        startedAt: day,
        endedAt: day.add(const Duration(minutes: 5)),
        durationMinutes: 30,
        status: FocusSessionStatus.completed,
        createdAt: day,
        updatedAt: day.add(const Duration(minutes: 5)),
      );

      expect(
        GoalDailyCompletionCalculator.isGoalCompletedOnDay(
          goalId: 'goal-1',
          day: day,
          focusModeEnabled: true,
          focusSessions: <FocusSession>[notEligible],
        ),
        isFalse,
      );

      expect(
        GoalDailyCompletionCalculator.isGoalCompletedOnDay(
          goalId: 'goal-1',
          day: day,
          focusModeEnabled: true,
          focusSessions: <FocusSession>[eligible],
        ),
        isTrue,
      );
    });

    test('focus mode ignores manual confirmations', () {
      final DateTime day = DateTime(2026, 3, 30, 12, 0);
      final ActionDayConfirmation manual = ActionDayConfirmation.create(
        goalId: 'goal-1',
        actionId: 'action-1',
        now: day,
      );

      expect(
        GoalDailyCompletionCalculator.isGoalCompletedOnDay(
          goalId: 'goal-1',
          day: day,
          focusModeEnabled: true,
          manualConfirmations: <ActionDayConfirmation>[manual],
        ),
        isFalse,
      );
    });

    test('checklist mode uses manual confirmations for the day', () {
      final DateTime day = DateTime(2026, 3, 30, 18, 0);
      final ActionDayConfirmation manual = ActionDayConfirmation.create(
        goalId: 'goal-1',
        actionId: 'action-1',
        now: day,
      );
      final FocusSession eligibleFocus = FocusSession(
        id: 'focus-1',
        goalId: 'goal-1',
        actionId: 'action-1',
        startedAt: day,
        endedAt: day.add(const Duration(minutes: 10)),
        durationMinutes: 30,
        status: FocusSessionStatus.completed,
        createdAt: day,
        updatedAt: day.add(const Duration(minutes: 10)),
      );

      expect(
        GoalDailyCompletionCalculator.isGoalCompletedOnDay(
          goalId: 'goal-1',
          day: day,
          focusModeEnabled: false,
          manualConfirmations: <ActionDayConfirmation>[manual],
          focusSessions: <FocusSession>[eligibleFocus],
        ),
        isTrue,
      );

      expect(
        GoalDailyCompletionCalculator.isGoalCompletedOnDay(
          goalId: 'goal-1',
          day: day,
          focusModeEnabled: false,
          manualConfirmations: const <ActionDayConfirmation>[],
          focusSessions: <FocusSession>[eligibleFocus],
        ),
        isFalse,
      );
    });

    test('manual confirmation is idempotent per action/day', () {
      final DateTime now = DateTime(2026, 3, 30, 19, 0);
      final ActionDayConfirmation existing = ActionDayConfirmation.create(
        goalId: 'goal-1',
        actionId: 'action-1',
        now: now,
      );

      expect(
        GoalDailyCompletionCalculator.canRegisterManualConfirmation(
          goalId: 'goal-1',
          actionId: 'action-1',
          now: now,
          existingConfirmations: <ActionDayConfirmation>[existing],
        ),
        isFalse,
      );

      expect(
        GoalDailyCompletionCalculator.canRegisterManualConfirmation(
          goalId: 'goal-1',
          actionId: 'action-1',
          now: now.add(const Duration(days: 1)),
          existingConfirmations: <ActionDayConfirmation>[existing],
        ),
        isTrue,
      );

      expect(
        GoalDailyCompletionCalculator.canRegisterManualConfirmation(
          goalId: 'goal-1',
          actionId: 'action-2',
          now: now,
          existingConfirmations: <ActionDayConfirmation>[existing],
        ),
        isTrue,
      );
    });

    test('focus mode uses local day even when session timestamp is UTC', () {
      final DateTime localNow = DateTime.now();
      final DateTime localStart = DateTime(
        localNow.year,
        localNow.month,
        localNow.day,
        9,
        0,
      );
      final DateTime localDayToCheck = DateTime(
        localNow.year,
        localNow.month,
        localNow.day,
        22,
        0,
      );
      final DateTime utcStored = localStart.toUtc();
      final FocusSession session = FocusSession(
        id: 'focus-utc-1',
        goalId: 'goal-1',
        actionId: 'action-1',
        startedAt: utcStored,
        endedAt: utcStored.add(const Duration(minutes: 6)),
        durationMinutes: 25,
        status: FocusSessionStatus.completed,
        createdAt: utcStored,
        updatedAt: utcStored.add(const Duration(minutes: 6)),
      );

      expect(
        GoalDailyCompletionCalculator.isGoalCompletedOnDay(
          goalId: 'goal-1',
          day: localDayToCheck,
          focusModeEnabled: true,
          focusSessions: <FocusSession>[session],
        ),
        isTrue,
      );
    });

    test(
      'checklist mode uses local day even when confirmation timestamp is UTC',
      () {
        final DateTime localNow = DateTime.now();
        final DateTime localConfirmationTime = DateTime(
          localNow.year,
          localNow.month,
          localNow.day,
          20,
          0,
        );
        final DateTime localDayToCheck = DateTime(
          localNow.year,
          localNow.month,
          localNow.day,
          8,
          0,
        );
        final DateTime utcStored = localConfirmationTime.toUtc();
        final ActionDayConfirmation confirmation = ActionDayConfirmation(
          id: 'manual-utc-1',
          goalId: 'goal-1',
          actionId: 'action-1',
          confirmedAt: utcStored,
          createdAt: utcStored,
          updatedAt: utcStored,
        );

        expect(
          GoalDailyCompletionCalculator.isGoalCompletedOnDay(
            goalId: 'goal-1',
            day: localDayToCheck,
            focusModeEnabled: false,
            manualConfirmations: <ActionDayConfirmation>[confirmation],
          ),
          isTrue,
        );
      },
    );
  });

  group('ActionWeeklyStatusCalculator', () {
    final DateTime monday = DateTime(2026, 3, 30, 9, 0);
    final DateTime wednesday = DateTime(2026, 4, 1, 9, 0);
    final DateTime thursday = DateTime(2026, 4, 2, 9, 0);

    final ActionItem baseAction = ActionItem(
      id: 'action-1',
      goalId: 'goal-1',
      title: 'Acao 1',
      isCompleted: false,
      createdAt: monday,
      updatedAt: monday,
      order: 0,
      completedAt: null,
    );

    test('returns done in focus mode when there is eligible focus on day', () {
      final FocusSession eligibleSession = FocusSession(
        id: 'session-1',
        goalId: 'goal-1',
        actionId: 'action-1',
        startedAt: monday,
        endedAt: monday.add(const Duration(minutes: 6)),
        durationMinutes: 25,
        status: FocusSessionStatus.completed,
        createdAt: monday,
        updatedAt: monday.add(const Duration(minutes: 6)),
      );

      final WeeklyActionDayStatus status =
          ActionWeeklyStatusCalculator.statusForDay(
            goalId: 'goal-1',
            action: baseAction,
            day: monday,
            referenceDate: monday,
            focusModeEnabled: true,
            focusSessions: <FocusSession>[eligibleSession],
          );

      expect(status, WeeklyActionDayStatus.done);
    });

    test('keeps day as done in focus mode with manual confirmation', () {
      final ActionDayConfirmation confirmation = ActionDayConfirmation.create(
        goalId: 'goal-1',
        actionId: 'action-1',
        now: monday,
      );

      final WeeklyActionDayStatus status =
          ActionWeeklyStatusCalculator.statusForDay(
            goalId: 'goal-1',
            action: baseAction,
            day: monday,
            referenceDate: monday,
            focusModeEnabled: true,
            manualConfirmations: <ActionDayConfirmation>[confirmation],
          );

      expect(status, WeeklyActionDayStatus.done);
    });

    test('returns pending for today without completion', () {
      final WeeklyActionDayStatus status =
          ActionWeeklyStatusCalculator.statusForDay(
            goalId: 'goal-1',
            action: baseAction,
            day: wednesday,
            referenceDate: wednesday,
            focusModeEnabled: false,
          );

      expect(status, WeeklyActionDayStatus.pending);
    });

    test('returns missed for past day without completion', () {
      final DateTime tuesday = monday.add(const Duration(days: 1));
      final WeeklyActionDayStatus status =
          ActionWeeklyStatusCalculator.statusForDay(
            goalId: 'goal-1',
            action: baseAction,
            day: tuesday,
            referenceDate: wednesday,
            focusModeEnabled: false,
          );

      expect(status, WeeklyActionDayStatus.missed);
    });

    test('returns done in checklist mode with manual confirmation', () {
      final ActionDayConfirmation confirmation = ActionDayConfirmation.create(
        goalId: 'goal-1',
        actionId: 'action-1',
        now: thursday,
      );

      final WeeklyActionDayStatus status =
          ActionWeeklyStatusCalculator.statusForDay(
            goalId: 'goal-1',
            action: baseAction,
            day: thursday,
            referenceDate: thursday,
            focusModeEnabled: false,
            manualConfirmations: <ActionDayConfirmation>[confirmation],
          );

      expect(status, WeeklyActionDayStatus.done);
    });

    test('returns done in checklist mode when action was completed on day', () {
      final ActionItem completedAction = baseAction.copyWith(
        isCompleted: true,
        completedAt: thursday,
      );

      final WeeklyActionDayStatus status =
          ActionWeeklyStatusCalculator.statusForDay(
            goalId: 'goal-1',
            action: completedAction,
            day: thursday,
            referenceDate: thursday,
            focusModeEnabled: false,
          );

      expect(status, WeeklyActionDayStatus.done);
    });

    test('buildWeekStatuses returns seven items from monday to sunday', () {
      final List<WeeklyActionDayStatus> statuses =
          ActionWeeklyStatusCalculator.buildWeekStatuses(
            goalId: 'goal-1',
            action: baseAction,
            focusModeEnabled: false,
            referenceDate: wednesday,
          );

      expect(statuses, hasLength(7));
      expect(statuses.first, WeeklyActionDayStatus.missed);
      expect(statuses[2], WeeklyActionDayStatus.pending);
      expect(statuses.last, WeeklyActionDayStatus.pending);
    });

    test('monthDays returns correct number of days for month length', () {
      final List<DateTime> februaryDays =
          ActionWeeklyStatusCalculator.monthDays(year: 2026, month: 2);
      final List<DateTime> marchDays = ActionWeeklyStatusCalculator.monthDays(
        year: 2026,
        month: 3,
      );

      expect(februaryDays, hasLength(28));
      expect(marchDays, hasLength(31));
      expect(februaryDays.first, DateTime(2026, 2, 1));
      expect(marchDays.last, DateTime(2026, 3, 31));
    });

    test('buildMonthStatuses returns monthly statuses for all days', () {
      final ActionDayConfirmation confirmation = ActionDayConfirmation.create(
        goalId: 'goal-1',
        actionId: 'action-1',
        now: DateTime(2026, 3, 10, 7),
      );

      final List<WeeklyActionDayStatus> statuses =
          ActionWeeklyStatusCalculator.buildMonthStatuses(
            goalId: 'goal-1',
            action: baseAction,
            year: 2026,
            month: 3,
            focusModeEnabled: false,
            referenceDate: DateTime(2026, 3, 15, 12),
            manualConfirmations: <ActionDayConfirmation>[confirmation],
          );

      expect(statuses, hasLength(31));
      expect(statuses[9], WeeklyActionDayStatus.done);
      expect(statuses[14], WeeklyActionDayStatus.pending);
      expect(statuses[29], WeeklyActionDayStatus.pending);
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quebrando_metas/features/goals/data/goals_repository.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/action_day_confirmation.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';
import 'package:quebrando_metas/features/goals/domain/focus_streak_calculator.dart';
import 'package:quebrando_metas/features/goals/domain/action_weekly_status_calculator.dart';
import 'package:quebrando_metas/features/goals/domain/goal_monthly_history.dart';
import 'package:quebrando_metas/features/goals/domain/goal_daily_completion_calculator.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';

final AsyncNotifierProviderFamily<
  GoalActionsController,
  List<ActionItem>,
  String
>
goalActionsControllerProvider =
    AsyncNotifierProviderFamily<
      GoalActionsController,
      List<ActionItem>,
      String
    >(GoalActionsController.new);

final FutureProviderFamily<List<ActionDayConfirmation>, String>
actionDayConfirmationsByGoalProvider =
    FutureProvider.family<List<ActionDayConfirmation>, String>((
      ref,
      goalId,
    ) async {
      return ref
          .read(goalsRepositoryProvider)
          .listActionDayConfirmations(goalId: goalId);
    });

final FutureProviderFamily<List<FocusSession>, String>
focusSessionsByGoalProvider = FutureProvider.family<List<FocusSession>, String>(
  (ref, goalId) async {
    return ref.read(goalsRepositoryProvider).listFocusSessions(goalId: goalId);
  },
);

final FutureProviderFamily<GoalMonthlyHistory, GoalMonthlyHistoryArgs>
goalMonthlyHistoryProvider =
    FutureProvider.family<GoalMonthlyHistory, GoalMonthlyHistoryArgs>((
      ref,
      args,
    ) async {
      final GoalsRepository repository = ref.read(goalsRepositoryProvider);
      final List<ActionItem> actions = await repository.listActions(
        args.goalId,
      );
      final List<FocusSession> sessions = await repository.listFocusSessions(
        goalId: args.goalId,
      );
      final List<ActionDayConfirmation> confirmations = await repository
          .listActionDayConfirmations(goalId: args.goalId);
      final List<DateTime> monthDays = ActionWeeklyStatusCalculator.monthDays(
        year: args.year,
        month: args.month,
      );
      final List<GoalMonthlyHistoryRow> rows = actions
          .map(
            (action) => GoalMonthlyHistoryRow(
              action: action,
              statuses: ActionWeeklyStatusCalculator.buildStatusesForDays(
                goalId: args.goalId,
                action: action,
                days: monthDays,
                focusModeEnabled: args.focusModeEnabled,
                referenceDate: args.referenceDate,
                focusSessions: sessions,
                manualConfirmations: confirmations,
              ),
            ),
          )
          .toList(growable: false);

      return GoalMonthlyHistory(
        goalId: args.goalId,
        year: args.year,
        month: args.month,
        days: monthDays,
        rows: rows,
      );
    });

enum ToggleActionResult { updated, blockedNoFocusTime }

class GoalActionsController
    extends FamilyAsyncNotifier<List<ActionItem>, String> {
  String get _goalId => arg;

  @override
  Future<List<ActionItem>> build(String goalId) async {
    await _reopenActionsFromPreviousDays(goalId);
    return ref.read(goalsRepositoryProvider).listActions(goalId);
  }

  Future<void> createAction({
    required String goalId,
    required String title,
  }) async {
    await ref
        .read(goalsRepositoryProvider)
        .createAction(goalId: goalId, title: title);
    await _reload();
  }

  Future<void> updateAction({
    required String goalId,
    required ActionItem action,
    required String title,
  }) async {
    await ref
        .read(goalsRepositoryProvider)
        .updateAction(action.copyWith(title: title, updatedAt: DateTime.now()));
    await _reload();
  }

  Future<ToggleActionResult> toggleAction({
    required String goalId,
    required ActionItem action,
    required bool isCompleted,
    bool enforceFocusRequirement = true,
  }) async {
    final DateTime timestamp = DateTime.now();
    if (enforceFocusRequirement &&
        isCompleted &&
        action.totalFocusMinutes <= 0) {
      final List<FocusSession> sessions = await ref
          .read(goalsRepositoryProvider)
          .listFocusSessions(goalId: goalId, actionId: action.id);
      final bool hasCompletedFocus = sessions.any(
        (session) => session.status == FocusSessionStatus.completed,
      );
      if (!hasCompletedFocus) {
        return ToggleActionResult.blockedNoFocusTime;
      }
    }

    final ActionItem updated = isCompleted
        ? action.markCompleted(now: timestamp)
        : action.markPending(now: timestamp);
    await ref.read(goalsRepositoryProvider).updateAction(updated);
    if (!enforceFocusRequirement && isCompleted) {
      await confirmActionDoneToday(
        goalId: goalId,
        actionId: action.id,
        now: timestamp,
      );
    }
    await _reload();
    return ToggleActionResult.updated;
  }

  Future<void> deleteAction({
    required String goalId,
    required String actionId,
  }) async {
    await ref
        .read(goalsRepositoryProvider)
        .deleteAction(goalId: goalId, actionId: actionId);
    ref.invalidate(focusStreakProvider);
    ref.invalidate(dailyCompletedActionsProvider);
    await _reload();
  }

  Future<bool> confirmActionDoneToday({
    required String goalId,
    required String actionId,
    DateTime? now,
  }) async {
    final DateTime timestamp = now ?? DateTime.now();
    final repository = ref.read(goalsRepositoryProvider);
    final List<ActionDayConfirmation> existingConfirmations = await repository
        .listActionDayConfirmations(goalId: goalId, actionId: actionId);
    final bool canRegister =
        GoalDailyCompletionCalculator.canRegisterManualConfirmation(
          goalId: goalId,
          actionId: actionId,
          now: timestamp,
          existingConfirmations: existingConfirmations,
        );
    if (!canRegister) {
      return false;
    }

    await repository.saveActionDayConfirmation(
      ActionDayConfirmation.create(
        goalId: goalId,
        actionId: actionId,
        now: timestamp,
      ),
    );
    ref.invalidate(actionDayConfirmationsByGoalProvider(goalId));
    ref.invalidate(dailyCompletedActionsProvider);
    return true;
  }

  Future<FocusSession> startFocusSession({
    required String goalId,
    required String actionId,
    required int durationMinutes,
    DateTime? now,
  }) async {
    final DateTime startedAt = now ?? DateTime.now();
    final FocusSession session = FocusSession.start(
      goalId: goalId,
      actionId: actionId,
      durationMinutes: durationMinutes,
      now: startedAt,
    );
    await ref.read(goalsRepositoryProvider).saveFocusSession(session);
    _invalidateGoalTracking(goalId);
    return session;
  }

  Future<int> completeFocusSession(
    FocusSession session, {
    int? elapsedMinutes,
    int? sessionDurationMinutes,
    DateTime? now,
  }) async {
    final DateTime timestamp = now ?? DateTime.now();
    final FocusSession completed = session.markCompleted(now: timestamp);
    final repository = ref.read(goalsRepositoryProvider);
    await repository.saveFocusSession(completed);
    final List<ActionItem> actions = await ref
        .read(goalsRepositoryProvider)
        .listActions(session.goalId);
    ActionItem? currentAction;
    for (final ActionItem action in actions) {
      if (action.id == session.actionId) {
        currentAction = action;
        break;
      }
    }
    final int minutesToAccumulate = _normalizeElapsedMinutes(
      sessionDurationMinutes:
          sessionDurationMinutes ?? completed.durationMinutes,
      elapsedMinutes: elapsedMinutes,
    );
    if (currentAction != null && minutesToAccumulate > 0) {
      ActionItem focusedAction = currentAction.registerFocus(
        durationMinutes: minutesToAccumulate,
        startedAt: completed.startedAt,
        now: timestamp,
      );
      if (minutesToAccumulate >= FocusSession.streakMinimumMinutes) {
        focusedAction = focusedAction.markCompleted(now: timestamp);
        await confirmActionDoneToday(
          goalId: session.goalId,
          actionId: session.actionId,
          now: timestamp,
        );
      }
      await repository.updateAction(focusedAction);
    }

    await _refreshStreakStats();
    _invalidateGoalTracking(session.goalId);
    await _reload();
    return currentAction == null ? 0 : minutesToAccumulate;
  }

  Future<int> cancelFocusSession(
    FocusSession session, {
    int? elapsedMinutes,
    int? sessionDurationMinutes,
    DateTime? now,
  }) async {
    final DateTime timestamp = now ?? DateTime.now();
    final FocusSession canceled = session.markCanceled(now: timestamp);
    final repository = ref.read(goalsRepositoryProvider);
    await repository.saveFocusSession(canceled);

    final int minutesToAccumulate = _normalizeElapsedMinutes(
      sessionDurationMinutes:
          sessionDurationMinutes ?? canceled.durationMinutes,
      elapsedMinutes: elapsedMinutes,
    );
    int accumulatedMinutes = 0;
    if (minutesToAccumulate >= 1) {
      final List<ActionItem> actions = await repository.listActions(
        session.goalId,
      );
      ActionItem? currentAction;
      for (final ActionItem action in actions) {
        if (action.id == session.actionId) {
          currentAction = action;
          break;
        }
      }
      if (currentAction != null) {
        final ActionItem focusedAction = currentAction.registerFocus(
          durationMinutes: minutesToAccumulate,
          startedAt: canceled.startedAt,
          now: timestamp,
        );
        await repository.updateAction(focusedAction);
        accumulatedMinutes = minutesToAccumulate;
      }
    }

    await _refreshStreakStats();
    _invalidateGoalTracking(session.goalId);
    await _reload();
    return accumulatedMinutes;
  }

  Future<void> _reload() async {
    await _reopenActionsFromPreviousDays(_goalId);
    final List<ActionItem> actions = await ref
        .read(goalsRepositoryProvider)
        .listActions(_goalId);
    state = AsyncData(actions);
    await ref.read(goalsControllerProvider.notifier).reload();
  }

  Future<void> _reopenActionsFromPreviousDays(String goalId) async {
    final GoalsRepository repository = ref.read(goalsRepositoryProvider);
    final DateTime now = DateTime.now();
    final DateTime today = _dateOnlyLocal(now);
    final List<ActionItem> actions = await repository.listActions(goalId);

    for (final ActionItem action in actions) {
      if (!_shouldReopenAction(action: action, today: today)) continue;
      await repository.updateAction(action.markPending(now: now));
    }
  }

  bool _shouldReopenAction({
    required ActionItem action,
    required DateTime today,
  }) {
    if (!action.isCompleted) return false;
    final DateTime? completedAt = action.completedAt;
    if (completedAt == null) return true;
    return _dateOnlyLocal(completedAt).isBefore(today);
  }

  DateTime _dateOnlyLocal(DateTime value) {
    final DateTime local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  int _normalizeElapsedMinutes({
    required int sessionDurationMinutes,
    int? elapsedMinutes,
  }) {
    final int rawElapsed = elapsedMinutes ?? sessionDurationMinutes;
    if (rawElapsed <= 0) return 0;
    if (rawElapsed > sessionDurationMinutes) {
      return sessionDurationMinutes;
    }
    return rawElapsed;
  }

  Future<void> _refreshStreakStats() async {
    final repository = ref.read(goalsRepositoryProvider);
    final List<FocusSession> sessions = await repository.listFocusSessions();

    final int bestStreakFromSessions =
        FocusStreakCalculator.bestStreakFromSessions(sessions);
    final int persistedBestStreak = await repository.getBestFocusStreak();
    final int resolvedBestStreak = bestStreakFromSessions > persistedBestStreak
        ? bestStreakFromSessions
        : persistedBestStreak;

    if (resolvedBestStreak != persistedBestStreak) {
      await repository.saveBestFocusStreak(resolvedBestStreak);
    }

    ref.invalidate(focusStreakProvider);
    ref.invalidate(bestFocusStreakProvider);
  }

  void _invalidateGoalTracking(String goalId) {
    ref.invalidate(focusSessionsByGoalProvider(goalId));
    ref.invalidate(actionDayConfirmationsByGoalProvider(goalId));
    ref.invalidate(dailyCompletedActionsProvider);
  }
}

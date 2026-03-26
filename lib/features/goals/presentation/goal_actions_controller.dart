import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';
import 'package:quebrando_metas/features/goals/domain/focus_streak_calculator.dart';
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

enum ToggleActionResult { updated, blockedNoFocusTime }

class GoalActionsController
    extends FamilyAsyncNotifier<List<ActionItem>, String> {
  String get _goalId => arg;

  @override
  Future<List<ActionItem>> build(String goalId) {
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
  }) async {
    if (isCompleted && action.totalFocusMinutes <= 0) {
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
        ? action.markCompleted()
        : action.markPending();
    await ref.read(goalsRepositoryProvider).updateAction(updated);
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
    await _reload();
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
    return session;
  }

  Future<int> completeFocusSession(
    FocusSession session, {
    int? elapsedMinutes,
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
      sessionDurationMinutes: completed.durationMinutes,
      elapsedMinutes: elapsedMinutes,
    );
    if (currentAction != null && minutesToAccumulate > 0) {
      final ActionItem focusedAction = currentAction.registerFocus(
        durationMinutes: minutesToAccumulate,
        startedAt: completed.startedAt,
        now: timestamp,
      );
      await repository.updateAction(focusedAction);
    }

    await _refreshStreakStats();
    await _reload();
    return currentAction == null ? 0 : minutesToAccumulate;
  }

  Future<int> cancelFocusSession(
    FocusSession session, {
    int? elapsedMinutes,
    DateTime? now,
  }) async {
    final DateTime timestamp = now ?? DateTime.now();
    final FocusSession canceled = session.markCanceled(now: timestamp);
    final repository = ref.read(goalsRepositoryProvider);
    await repository.saveFocusSession(canceled);

    final int minutesToAccumulate = _normalizeElapsedMinutes(
      sessionDurationMinutes: canceled.durationMinutes,
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
    await _reload();
    return accumulatedMinutes;
  }

  Future<void> _reload() async {
    final List<ActionItem> actions = await ref
        .read(goalsRepositoryProvider)
        .listActions(_goalId);
    state = AsyncData(actions);
    await ref.read(goalsControllerProvider.notifier).reload();
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
}

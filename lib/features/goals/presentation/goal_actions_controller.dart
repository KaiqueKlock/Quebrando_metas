import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';
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
    await _reload();
  }

  Future<FocusSession> startFocusSession({
    required String goalId,
    required String actionId,
    required int durationMinutes,
  }) async {
    final FocusSession session = FocusSession.start(
      goalId: goalId,
      actionId: actionId,
      durationMinutes: durationMinutes,
    );
    await ref.read(goalsRepositoryProvider).saveFocusSession(session);
    return session;
  }

  Future<int> completeFocusSession(
    FocusSession session, {
    int? elapsedMinutes,
  }) async {
    final FocusSession completed = session.markCompleted();
    await ref.read(goalsRepositoryProvider).saveFocusSession(completed);
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
    if (currentAction == null) {
      return 0;
    }

    final int minutesToAccumulate = _normalizeElapsedMinutes(
      sessionDurationMinutes: completed.durationMinutes,
      elapsedMinutes: elapsedMinutes,
    );
    if (minutesToAccumulate <= 0) {
      return 0;
    }

    final ActionItem focusedAction = currentAction.registerFocus(
      durationMinutes: minutesToAccumulate,
      startedAt: completed.startedAt,
      now: DateTime.now(),
    );
    await ref.read(goalsRepositoryProvider).updateAction(focusedAction);
    await _reload();
    return minutesToAccumulate;
  }

  Future<void> cancelFocusSession(FocusSession session) async {
    final FocusSession canceled = session.markCanceled();
    await ref.read(goalsRepositoryProvider).saveFocusSession(canceled);
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
}

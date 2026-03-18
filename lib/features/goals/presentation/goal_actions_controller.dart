import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';

final AsyncNotifierProviderFamily<GoalActionsController, List<ActionItem>, String>
    goalActionsControllerProvider =
    AsyncNotifierProviderFamily<GoalActionsController, List<ActionItem>, String>(
  GoalActionsController.new,
);

class GoalActionsController extends FamilyAsyncNotifier<List<ActionItem>, String> {
  String get _goalId => arg;

  @override
  Future<List<ActionItem>> build(String goalId) {
    return ref.read(goalsRepositoryProvider).listActions(goalId);
  }

  Future<void> createAction({
    required String goalId,
    required String title,
  }) async {
    await ref.read(goalsRepositoryProvider).createAction(
          goalId: goalId,
          title: title,
        );
    await _reload();
  }

  Future<void> updateAction({
    required String goalId,
    required ActionItem action,
    required String title,
  }) async {
    await ref.read(goalsRepositoryProvider).updateAction(
          action.copyWith(
            title: title,
            updatedAt: DateTime.now(),
          ),
        );
    await _reload();
  }

  Future<void> toggleAction({
    required String goalId,
    required ActionItem action,
    required bool isCompleted,
  }) async {
    final ActionItem updated = isCompleted ? action.markCompleted() : action.markPending();
    await ref.read(goalsRepositoryProvider).updateAction(updated);
    await _reload();
  }

  Future<void> deleteAction({
    required String goalId,
    required String actionId,
  }) async {
    await ref.read(goalsRepositoryProvider).deleteAction(
          goalId: goalId,
          actionId: actionId,
        );
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

  Future<void> completeFocusSession(FocusSession session) async {
    final FocusSession completed = session.markCompleted();
    await ref.read(goalsRepositoryProvider).saveFocusSession(completed);
  }

  Future<void> cancelFocusSession(FocusSession session) async {
    final FocusSession canceled = session.markCanceled();
    await ref.read(goalsRepositoryProvider).saveFocusSession(canceled);
  }

  Future<void> _reload() async {
    final List<ActionItem> actions =
        await ref.read(goalsRepositoryProvider).listActions(_goalId);
    state = AsyncData(actions);
    await ref.read(goalsControllerProvider.notifier).reload();
  }
}

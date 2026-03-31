import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/action_day_confirmation.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';

abstract class GoalsRepository {
  const GoalsRepository();

  Future<List<Goal>> listGoals();
  Future<Goal> createGoal({required String title, String? description});
  Future<Goal> updateGoal(Goal goal);
  Future<void> deleteGoal(String goalId);

  Future<List<ActionItem>> listActions(String goalId);
  Future<ActionItem> createAction({
    required String goalId,
    required String title,
  });
  Future<ActionItem> updateAction(ActionItem action);
  Future<void> deleteAction({required String goalId, required String actionId});

  Future<List<FocusSession>> listFocusSessions({
    String? goalId,
    String? actionId,
  });
  Future<FocusSession> saveFocusSession(FocusSession session);
  Future<void> deleteFocusSession(String sessionId);
  Future<List<ActionDayConfirmation>> listActionDayConfirmations({
    String? goalId,
    String? actionId,
    DateTime? day,
  });
  Future<ActionDayConfirmation> saveActionDayConfirmation(
    ActionDayConfirmation confirmation,
  );
  Future<void> deleteActionDayConfirmation(String confirmationId);
  Future<int> getBestFocusStreak();
  Future<void> saveBestFocusStreak(int bestStreak);
}

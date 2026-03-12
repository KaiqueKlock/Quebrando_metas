import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';

abstract class GoalsRepository {
  const GoalsRepository();

  Future<List<Goal>> listGoals();
  Future<Goal> createGoal({
    required String title,
    String? description,
  });
  Future<Goal> updateGoal(Goal goal);
  Future<void> deleteGoal(String goalId);

  Future<List<ActionItem>> listActions(String goalId);
  Future<ActionItem> createAction({
    required String goalId,
    required String title,
  });
  Future<ActionItem> updateAction(ActionItem action);
  Future<void> deleteAction({
    required String goalId,
    required String actionId,
  });
}

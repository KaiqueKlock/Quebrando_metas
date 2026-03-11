import 'package:quebrando_metas/features/goals/domain/goal.dart';

abstract class GoalsRepository {
  const GoalsRepository();

  Future<List<Goal>> listGoals();
  Future<Goal> createGoal({
    required String title,
    String? description,
  });
  Future<Goal> updateGoal(Goal goal);
  Future<void> deleteGoal(String goalId);
}

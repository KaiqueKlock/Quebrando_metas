import 'package:quebrando_metas/core/errors/app_exception.dart';
import 'package:quebrando_metas/features/goals/data/goals_repository.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';

class FakeInMemoryGoalsRepository implements GoalsRepository {
  FakeInMemoryGoalsRepository();

  final List<Goal> _goals = <Goal>[];

  @override
  Future<List<Goal>> listGoals() async {
    return List<Goal>.from(_goals)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<Goal> createGoal({
    required String title,
    String? description,
  }) async {
    final Goal goal = Goal.create(
      title: title,
      description: description,
    );
    _goals.add(goal);
    return goal;
  }

  @override
  Future<Goal> updateGoal(Goal goal) async {
    final int index = _goals.indexWhere((item) => item.id == goal.id);
    if (index == -1) {
      throw AppException('Goal not found: ${goal.id}');
    }

    _goals[index] = goal;
    return goal;
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    _goals.removeWhere((goal) => goal.id == goalId);
  }
}

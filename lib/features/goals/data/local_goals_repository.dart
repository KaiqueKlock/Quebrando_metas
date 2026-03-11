import 'package:hive_flutter/hive_flutter.dart';
import 'package:quebrando_metas/core/errors/app_exception.dart';
import 'package:quebrando_metas/features/goals/data/goal_mapper.dart';
import 'package:quebrando_metas/features/goals/data/goals_repository.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';

class LocalGoalsRepository implements GoalsRepository {
  LocalGoalsRepository();

  static const String _boxName = 'goals_box';
  late final Future<Box<Map<dynamic, dynamic>>> _boxFuture = _openBox();

  Future<Box<Map<dynamic, dynamic>>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<Map<dynamic, dynamic>>(_boxName);
    }

    return Hive.openBox<Map<dynamic, dynamic>>(_boxName);
  }

  @override
  Future<List<Goal>> listGoals() async {
    final Box<Map<dynamic, dynamic>> box = await _boxFuture;
    final List<Goal> goals = box.values
        .map((goalMap) => GoalMapper.fromMap(goalMap))
        .toList(growable: false);

    goals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return goals;
  }

  @override
  Future<Goal> createGoal({
    required String title,
    String? description,
  }) async {
    final Box<Map<dynamic, dynamic>> box = await _boxFuture;
    final Goal goal = Goal.create(
      title: title,
      description: description,
    );

    await box.put(goal.id, GoalMapper.toMap(goal));
    return goal;
  }

  @override
  Future<Goal> updateGoal(Goal goal) async {
    final Box<Map<dynamic, dynamic>> box = await _boxFuture;
    if (!box.containsKey(goal.id)) {
      throw AppException('Goal not found: ${goal.id}');
    }

    await box.put(goal.id, GoalMapper.toMap(goal));
    return goal;
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    final Box<Map<dynamic, dynamic>> box = await _boxFuture;
    await box.delete(goalId);
  }
}

import 'package:quebrando_metas/core/errors/app_exception.dart';
import 'package:quebrando_metas/features/goals/data/goals_repository.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';

class FakeInMemoryGoalsRepository implements GoalsRepository {
  FakeInMemoryGoalsRepository({
    List<Goal> initialGoals = const <Goal>[],
    List<ActionItem> initialActions = const <ActionItem>[],
  })  : _goals = List<Goal>.from(initialGoals),
        _actions = List<ActionItem>.from(initialActions) {
    _syncGoalCounters();
  }

  final List<Goal> _goals;
  final List<ActionItem> _actions;

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
    _actions.removeWhere((action) => action.goalId == goalId);
  }

  @override
  Future<List<ActionItem>> listActions(String goalId) async {
    final List<ActionItem> actions =
        _actions.where((action) => action.goalId == goalId).toList(growable: false);
    return actions..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Future<ActionItem> createAction({
    required String goalId,
    required String title,
  }) async {
    final List<ActionItem> actions = await listActions(goalId);
    final ActionItem action = ActionItem.create(
      goalId: goalId,
      title: title,
      order: actions.length,
    );
    _actions.add(action);
    await _recalculateGoal(goalId);
    return action;
  }

  @override
  Future<ActionItem> updateAction(ActionItem action) async {
    final int index = _actions.indexWhere((item) => item.id == action.id);
    if (index == -1) {
      throw AppException('Action not found: ${action.id}');
    }

    _actions[index] = action;
    await _recalculateGoal(action.goalId);
    return action;
  }

  @override
  Future<void> deleteAction({
    required String goalId,
    required String actionId,
  }) async {
    _actions.removeWhere((action) => action.id == actionId);
    await _normalizeActionOrder(goalId);
    await _recalculateGoal(goalId);
  }

  Future<void> _normalizeActionOrder(String goalId) async {
    final List<ActionItem> actions =
        _actions.where((action) => action.goalId == goalId).toList(growable: false)
          ..sort((a, b) => a.order.compareTo(b.order));

    for (int i = 0; i < actions.length; i++) {
      final ActionItem action = actions[i];
      final int index = _actions.indexWhere((item) => item.id == action.id);
      _actions[index] = action.copyWith(order: i, updatedAt: DateTime.now());
    }
  }

  Future<void> _recalculateGoal(String goalId) async {
    final int goalIndex = _goals.indexWhere((goal) => goal.id == goalId);
    if (goalIndex == -1) return;

    final List<ActionItem> actions =
        _actions.where((action) => action.goalId == goalId).toList(growable: false);
    final int completed = actions.where((action) => action.isCompleted).length;
    final Goal goal = _goals[goalIndex];
    _goals[goalIndex] = goal.copyWith(
      completedActions: completed,
      totalActions: actions.length,
      updatedAt: DateTime.now(),
    );
  }

  void _syncGoalCounters() {
    for (int i = 0; i < _goals.length; i++) {
      final Goal goal = _goals[i];
      final List<ActionItem> actions =
          _actions.where((action) => action.goalId == goal.id).toList(growable: false);
      final int completed = actions.where((action) => action.isCompleted).length;
      _goals[i] = goal.copyWith(
        completedActions: completed,
        totalActions: actions.length,
      );
    }
  }
}

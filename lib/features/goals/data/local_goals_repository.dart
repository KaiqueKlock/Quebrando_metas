import 'package:hive_flutter/hive_flutter.dart';
import 'package:quebrando_metas/core/errors/app_exception.dart';
import 'package:quebrando_metas/features/goals/data/action_mapper.dart';
import 'package:quebrando_metas/features/goals/data/goal_mapper.dart';
import 'package:quebrando_metas/features/goals/data/goals_repository.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';

class LocalGoalsRepository implements GoalsRepository {
  LocalGoalsRepository();

  static const String _goalsBoxName = 'goals_box';
  static const String _actionsBoxName = 'actions_box';

  late final Future<Box<Map<String, dynamic>>> _goalsBoxFuture = _openBox(_goalsBoxName);
  late final Future<Box<Map<String, dynamic>>> _actionsBoxFuture = _openBox(_actionsBoxName);

  Future<Box<Map<String, dynamic>>> _openBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<Map<String, dynamic>>(boxName);
    }

    return Hive.openBox<Map<String, dynamic>>(boxName);
  }

  @override
  Future<List<Goal>> listGoals() async {
    final Box<Map<String, dynamic>> box = await _goalsBoxFuture;
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
    final Box<Map<String, dynamic>> box = await _goalsBoxFuture;
    final Goal goal = Goal.create(
      title: title,
      description: description,
    );

    await box.put(goal.id, GoalMapper.toMap(goal));
    return goal;
  }

  @override
  Future<Goal> updateGoal(Goal goal) async {
    final Box<Map<String, dynamic>> box = await _goalsBoxFuture;
    if (!box.containsKey(goal.id)) {
      throw AppException('Goal not found: ${goal.id}');
    }

    await box.put(goal.id, GoalMapper.toMap(goal));
    return goal;
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    final Box<Map<String, dynamic>> goalsBox = await _goalsBoxFuture;
    final Box<Map<String, dynamic>> actionsBox = await _actionsBoxFuture;

    final List<String> actionIds = actionsBox.values
        .where((map) => map['goalId'] == goalId)
        .map((map) => map['id'] as String)
        .toList(growable: false);

    for (final String actionId in actionIds) {
      await actionsBox.delete(actionId);
    }

    await goalsBox.delete(goalId);
  }

  @override
  Future<List<ActionItem>> listActions(String goalId) async {
    final Box<Map<String, dynamic>> actionsBox = await _actionsBoxFuture;
    final List<ActionItem> actions = actionsBox.values
        .where((actionMap) => actionMap['goalId'] == goalId)
        .map((actionMap) => ActionMapper.fromMap(actionMap))
        .toList(growable: false);

    actions.sort((a, b) => a.order.compareTo(b.order));
    return actions;
  }

  @override
  Future<ActionItem> createAction({
    required String goalId,
    required String title,
  }) async {
    final Box<Map<String, dynamic>> actionsBox = await _actionsBoxFuture;
    final List<ActionItem> currentActions = await listActions(goalId);
    final ActionItem action = ActionItem.create(
      goalId: goalId,
      title: title,
      order: currentActions.length,
    );

    await actionsBox.put(action.id, ActionMapper.toMap(action));
    await _recalculateGoalCounters(goalId);
    return action;
  }

  @override
  Future<ActionItem> updateAction(ActionItem action) async {
    final Box<Map<String, dynamic>> actionsBox = await _actionsBoxFuture;
    if (!actionsBox.containsKey(action.id)) {
      throw AppException('Action not found: ${action.id}');
    }

    await actionsBox.put(action.id, ActionMapper.toMap(action));
    await _recalculateGoalCounters(action.goalId);
    return action;
  }

  @override
  Future<void> deleteAction({
    required String goalId,
    required String actionId,
  }) async {
    final Box<Map<String, dynamic>> actionsBox = await _actionsBoxFuture;
    await actionsBox.delete(actionId);
    await _normalizeOrder(goalId);
    await _recalculateGoalCounters(goalId);
  }

  Future<void> _normalizeOrder(String goalId) async {
    final Box<Map<String, dynamic>> actionsBox = await _actionsBoxFuture;
    final List<ActionItem> actions = await listActions(goalId);

    for (int i = 0; i < actions.length; i++) {
      final ActionItem action = actions[i];
      if (action.order != i) {
        final ActionItem normalized = action.copyWith(
          order: i,
          updatedAt: DateTime.now(),
        );
        await actionsBox.put(normalized.id, ActionMapper.toMap(normalized));
      }
    }
  }

  Future<void> _recalculateGoalCounters(String goalId) async {
    final Box<Map<String, dynamic>> goalsBox = await _goalsBoxFuture;
    final Map<String, dynamic>? goalMap = goalsBox.get(goalId);
    if (goalMap == null) return;

    final Goal goal = GoalMapper.fromMap(goalMap);
    final List<ActionItem> actions = await listActions(goalId);
    final int totalActions = actions.length;
    final int completedActions = actions.where((action) => action.isCompleted).length;

    final Goal updatedGoal = goal.copyWith(
      completedActions: completedActions,
      totalActions: totalActions,
      updatedAt: DateTime.now(),
    );

    await goalsBox.put(goalId, GoalMapper.toMap(updatedGoal));
  }
}

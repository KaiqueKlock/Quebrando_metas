import 'package:hive_flutter/hive_flutter.dart';
import 'package:quebrando_metas/core/errors/app_exception.dart';
import 'package:quebrando_metas/features/goals/data/action_mapper.dart';
import 'package:quebrando_metas/features/goals/data/focus_session_mapper.dart';
import 'package:quebrando_metas/features/goals/data/goal_mapper.dart';
import 'package:quebrando_metas/features/goals/data/goals_repository.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';

class LocalGoalsRepository implements GoalsRepository {
  LocalGoalsRepository();

  static const String _goalsBoxName = 'goals_box';
  static const String _actionsBoxName = 'actions_box';
  static const String _focusSessionsBoxName = 'focus_sessions_box';

  late final Future<Box<dynamic>> _goalsBoxFuture = _openBox(_goalsBoxName);
  late final Future<Box<dynamic>> _actionsBoxFuture = _openBox(_actionsBoxName);
  late final Future<Box<dynamic>> _focusSessionsBoxFuture = _openBox(
    _focusSessionsBoxName,
  );

  Future<Box<dynamic>> _openBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<dynamic>(boxName);
    }

    return Hive.openBox<dynamic>(boxName);
  }

  @override
  Future<List<Goal>> listGoals() async {
    final Box<dynamic> box = await _goalsBoxFuture;
    final List<Goal> goals = <Goal>[];
    for (final dynamic rawGoal in box.values) {
      final Map<String, dynamic>? goalMap = _coerceMap(rawGoal);
      if (goalMap == null) continue;
      try {
        final Goal goal = GoalMapper.fromMap(goalMap);
        if (goal.id.isEmpty || goal.title.isEmpty) {
          continue;
        }
        goals.add(goal);
      } catch (_) {
        continue;
      }
    }

    goals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List<Goal>.unmodifiable(goals);
  }

  @override
  Future<Goal> createGoal({
    required String title,
    String? description,
  }) async {
    final Box<dynamic> box = await _goalsBoxFuture;
    final Goal goal = Goal.create(
      title: title,
      description: description,
    );

    await box.put(goal.id, GoalMapper.toMap(goal));
    return goal;
  }

  @override
  Future<Goal> updateGoal(Goal goal) async {
    final Box<dynamic> box = await _goalsBoxFuture;
    if (!box.containsKey(goal.id)) {
      throw AppException('Goal not found: ${goal.id}');
    }

    await box.put(goal.id, GoalMapper.toMap(goal));
    return goal;
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    final Box<dynamic> goalsBox = await _goalsBoxFuture;
    final Box<dynamic> actionsBox = await _actionsBoxFuture;
    final Box<dynamic> focusSessionsBox = await _focusSessionsBoxFuture;
    final List<String> actionIds = <String>[];
    for (final dynamic rawAction in actionsBox.values) {
      final Map<String, dynamic>? actionMap = _coerceMap(rawAction);
      if (actionMap == null) continue;
      if (actionMap['goalId'] != goalId) continue;

      final String actionId = (actionMap['id'] ?? '').toString();
      if (actionId.isNotEmpty) {
        actionIds.add(actionId);
      }
    }

    for (final String actionId in actionIds) {
      await actionsBox.delete(actionId);
    }

    final List<String> focusSessionIds = <String>[];
    for (final dynamic rawSession in focusSessionsBox.values) {
      final Map<String, dynamic>? sessionMap = _coerceMap(rawSession);
      if (sessionMap == null) continue;

      final String sessionGoalId = (sessionMap['goalId'] ?? '').toString();
      if (sessionGoalId != goalId) continue;

      final String sessionId = (sessionMap['id'] ?? '').toString();
      if (sessionId.isNotEmpty) {
        focusSessionIds.add(sessionId);
      }
    }

    for (final String sessionId in focusSessionIds) {
      await focusSessionsBox.delete(sessionId);
    }

    await goalsBox.delete(goalId);
  }

  @override
  Future<List<ActionItem>> listActions(String goalId) async {
    final Box<dynamic> actionsBox = await _actionsBoxFuture;
    final List<ActionItem> actions = <ActionItem>[];
    for (final dynamic rawAction in actionsBox.values) {
      final Map<String, dynamic>? actionMap = _coerceMap(rawAction);
      if (actionMap == null) continue;
      try {
        final ActionItem action = ActionMapper.fromMap(actionMap);
        if (action.id.isEmpty || action.goalId != goalId) {
          continue;
        }
        actions.add(action);
      } catch (_) {
        continue;
      }
    }

    actions.sort((a, b) => a.order.compareTo(b.order));
    return List<ActionItem>.unmodifiable(actions);
  }

  @override
  Future<ActionItem> createAction({
    required String goalId,
    required String title,
  }) async {
    final Box<dynamic> actionsBox = await _actionsBoxFuture;
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
    final Box<dynamic> actionsBox = await _actionsBoxFuture;
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
    final Box<dynamic> actionsBox = await _actionsBoxFuture;
    final Box<dynamic> focusSessionsBox = await _focusSessionsBoxFuture;
    await actionsBox.delete(actionId);

    final List<String> focusSessionIds = <String>[];
    for (final dynamic rawSession in focusSessionsBox.values) {
      final Map<String, dynamic>? sessionMap = _coerceMap(rawSession);
      if (sessionMap == null) continue;

      final String sessionActionId = (sessionMap['actionId'] ?? '').toString();
      if (sessionActionId != actionId) continue;

      final String sessionId = (sessionMap['id'] ?? '').toString();
      if (sessionId.isNotEmpty) {
        focusSessionIds.add(sessionId);
      }
    }

    for (final String sessionId in focusSessionIds) {
      await focusSessionsBox.delete(sessionId);
    }

    await _normalizeOrder(goalId);
    await _recalculateGoalCounters(goalId);
  }

  @override
  Future<List<FocusSession>> listFocusSessions({
    String? goalId,
    String? actionId,
  }) async {
    final Box<dynamic> sessionsBox = await _focusSessionsBoxFuture;
    final List<FocusSession> sessions = <FocusSession>[];

    for (final dynamic rawSession in sessionsBox.values) {
      final Map<String, dynamic>? sessionMap = _coerceMap(rawSession);
      if (sessionMap == null) continue;

      try {
        final FocusSession session = FocusSessionMapper.fromMap(sessionMap);
        if (session.id.isEmpty) continue;
        if (goalId != null && session.goalId != goalId) continue;
        if (actionId != null && session.actionId != actionId) continue;
        sessions.add(session);
      } catch (_) {
        continue;
      }
    }

    sessions.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return List<FocusSession>.unmodifiable(sessions);
  }

  @override
  Future<FocusSession> saveFocusSession(FocusSession session) async {
    final Box<dynamic> sessionsBox = await _focusSessionsBoxFuture;
    await sessionsBox.put(session.id, FocusSessionMapper.toMap(session));
    return session;
  }

  @override
  Future<void> deleteFocusSession(String sessionId) async {
    final Box<dynamic> sessionsBox = await _focusSessionsBoxFuture;
    await sessionsBox.delete(sessionId);
  }

  Future<void> _normalizeOrder(String goalId) async {
    final Box<dynamic> actionsBox = await _actionsBoxFuture;
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
    final Box<dynamic> goalsBox = await _goalsBoxFuture;
    final Map<String, dynamic>? goalMap = _coerceMap(goalsBox.get(goalId));
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

  Map<String, dynamic>? _coerceMap(dynamic raw) {
    if (raw is! Map) return null;
    return raw.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
}

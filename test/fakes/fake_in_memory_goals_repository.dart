import 'package:quebrando_metas/core/errors/app_exception.dart';
import 'package:quebrando_metas/features/goals/data/goals_repository.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/action_day_confirmation.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';

class FakeInMemoryGoalsRepository implements GoalsRepository {
  FakeInMemoryGoalsRepository({
    List<Goal> initialGoals = const <Goal>[],
    List<ActionItem> initialActions = const <ActionItem>[],
    List<FocusSession> initialFocusSessions = const <FocusSession>[],
    List<ActionDayConfirmation> initialActionDayConfirmations =
        const <ActionDayConfirmation>[],
    int initialBestFocusStreak = 0,
  }) : _goals = List<Goal>.from(initialGoals),
       _actions = List<ActionItem>.from(initialActions),
       _focusSessions = List<FocusSession>.from(initialFocusSessions),
       _actionDayConfirmations = List<ActionDayConfirmation>.from(
         initialActionDayConfirmations,
       ),
       _bestFocusStreak = initialBestFocusStreak < 0
           ? 0
           : initialBestFocusStreak {
    _syncGoalCounters();
  }

  final List<Goal> _goals;
  final List<ActionItem> _actions;
  final List<FocusSession> _focusSessions;
  final List<ActionDayConfirmation> _actionDayConfirmations;
  int _bestFocusStreak;

  @override
  Future<List<Goal>> listGoals() async {
    return List<Goal>.from(_goals)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<Goal> createGoal({required String title, String? description}) async {
    final Goal goal = Goal.create(title: title, description: description);
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
    final Set<String> deletedActionIds = _actions
        .where((action) => action.goalId == goalId)
        .map((action) => action.id)
        .toSet();
    _actions.removeWhere((action) => action.goalId == goalId);
    _focusSessions.removeWhere(
      (session) =>
          session.goalId == goalId ||
          deletedActionIds.contains(session.actionId),
    );
    _actionDayConfirmations.removeWhere(
      (confirmation) =>
          confirmation.goalId == goalId ||
          deletedActionIds.contains(confirmation.actionId),
    );
  }

  @override
  Future<List<ActionItem>> listActions(String goalId) async {
    final List<ActionItem> actions = _actions
        .where((action) => action.goalId == goalId)
        .toList(growable: false);
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
    _focusSessions.removeWhere((session) => session.actionId == actionId);
    _actionDayConfirmations.removeWhere(
      (confirmation) => confirmation.actionId == actionId,
    );
    await _normalizeActionOrder(goalId);
    await _recalculateGoal(goalId);
  }

  @override
  Future<List<FocusSession>> listFocusSessions({
    String? goalId,
    String? actionId,
  }) async {
    final List<FocusSession> sessions = _focusSessions
        .where((session) {
          if (goalId != null && session.goalId != goalId) return false;
          if (actionId != null && session.actionId != actionId) return false;
          return true;
        })
        .toList(growable: false);
    sessions.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return sessions;
  }

  @override
  Future<FocusSession> saveFocusSession(FocusSession session) async {
    final int index = _focusSessions.indexWhere(
      (item) => item.id == session.id,
    );
    if (index == -1) {
      _focusSessions.add(session);
      return session;
    }

    _focusSessions[index] = session;
    return session;
  }

  @override
  Future<void> deleteFocusSession(String sessionId) async {
    _focusSessions.removeWhere((session) => session.id == sessionId);
  }

  @override
  Future<List<ActionDayConfirmation>> listActionDayConfirmations({
    String? goalId,
    String? actionId,
    DateTime? day,
  }) async {
    final DateTime? normalizedDay = day == null ? null : _dateOnlyLocal(day);
    final List<ActionDayConfirmation> confirmations = _actionDayConfirmations
        .where((confirmation) {
          if (goalId != null && confirmation.goalId != goalId) return false;
          if (actionId != null && confirmation.actionId != actionId) {
            return false;
          }
          if (normalizedDay != null &&
              _dateOnlyLocal(confirmation.confirmedAt) != normalizedDay) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    confirmations.sort((a, b) => a.confirmedAt.compareTo(b.confirmedAt));
    return confirmations;
  }

  @override
  Future<ActionDayConfirmation> saveActionDayConfirmation(
    ActionDayConfirmation confirmation,
  ) async {
    final int index = _actionDayConfirmations.indexWhere(
      (item) => item.id == confirmation.id,
    );
    if (index == -1) {
      _actionDayConfirmations.add(confirmation);
      return confirmation;
    }
    _actionDayConfirmations[index] = confirmation;
    return confirmation;
  }

  @override
  Future<void> deleteActionDayConfirmation(String confirmationId) async {
    _actionDayConfirmations.removeWhere(
      (confirmation) => confirmation.id == confirmationId,
    );
  }

  @override
  Future<int> getBestFocusStreak() async {
    return _bestFocusStreak;
  }

  @override
  Future<void> saveBestFocusStreak(int bestStreak) async {
    _bestFocusStreak = bestStreak < 0 ? 0 : bestStreak;
  }

  Future<void> _normalizeActionOrder(String goalId) async {
    final List<ActionItem> actions =
        _actions
            .where((action) => action.goalId == goalId)
            .toList(growable: false)
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

    final List<ActionItem> actions = _actions
        .where((action) => action.goalId == goalId)
        .toList(growable: false);
    final int completed = actions.where((action) => action.isCompleted).length;
    final int totalFocusMinutes = actions.fold<int>(
      0,
      (sum, action) => sum + action.totalFocusMinutes,
    );
    final Goal goal = _goals[goalIndex];
    _goals[goalIndex] = goal.copyWith(
      completedActions: completed,
      totalActions: actions.length,
      totalFocusMinutes: totalFocusMinutes,
      updatedAt: DateTime.now(),
    );
  }

  void _syncGoalCounters() {
    for (int i = 0; i < _goals.length; i++) {
      final Goal goal = _goals[i];
      final List<ActionItem> actions = _actions
          .where((action) => action.goalId == goal.id)
          .toList(growable: false);
      final int completed = actions
          .where((action) => action.isCompleted)
          .length;
      final int totalFocusMinutes = actions.fold<int>(
        0,
        (sum, action) => sum + action.totalFocusMinutes,
      );
      _goals[i] = goal.copyWith(
        completedActions: completed,
        totalActions: actions.length,
        totalFocusMinutes: totalFocusMinutes,
      );
    }
  }

  DateTime _dateOnlyLocal(DateTime value) {
    final DateTime local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}

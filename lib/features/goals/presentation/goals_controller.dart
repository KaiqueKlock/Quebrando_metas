import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quebrando_metas/features/goals/data/local_goals_repository.dart';
import 'package:quebrando_metas/features/goals/data/goals_repository.dart';
import 'package:quebrando_metas/features/goals/domain/action_day_confirmation.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';
import 'package:quebrando_metas/features/goals/domain/focus_streak_calculator.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';

final LocalGoalsRepository _localGoalsRepository = LocalGoalsRepository();

final Provider<GoalsRepository> goalsRepositoryProvider =
    Provider<GoalsRepository>((ref) {
      return _localGoalsRepository;
    });

final AsyncNotifierProvider<GoalsController, List<Goal>>
goalsControllerProvider = AsyncNotifierProvider<GoalsController, List<Goal>>(
  GoalsController.new,
);

final ProviderFamily<Goal?, String> goalByIdProvider =
    Provider.family<Goal?, String>((ref, goalId) {
      final AsyncValue<List<Goal>> goalsAsync = ref.watch(
        goalsControllerProvider,
      );
      return goalsAsync.maybeWhen(
        data: (goals) {
          for (final Goal goal in goals) {
            if (goal.id == goalId) return goal;
          }
          return null;
        },
        orElse: () => null,
      );
    });

final FutureProvider<int> focusStreakProvider = FutureProvider<int>((
  ref,
) async {
  final GoalsRepository repository = ref.watch(goalsRepositoryProvider);
  final List<FocusSession> sessions = await repository.listFocusSessions();
  return FocusStreakCalculator.currentStreakFromSessions(
    sessions,
    now: DateTime.now(),
  );
});

final FutureProvider<int> bestFocusStreakProvider = FutureProvider<int>((
  ref,
) async {
  final GoalsRepository repository = ref.watch(goalsRepositoryProvider);
  final int persistedBest = await repository.getBestFocusStreak();
  if (persistedBest > 0) {
    return persistedBest;
  }

  final List<FocusSession> sessions = await repository.listFocusSessions();
  final int migratedBest = FocusStreakCalculator.bestStreakFromSessions(
    sessions,
  );
  if (migratedBest > persistedBest) {
    await repository.saveBestFocusStreak(migratedBest);
    return migratedBest;
  }
  return persistedBest;
});

final FutureProvider<int> dailyCompletedActionsProvider = FutureProvider<int>((
  ref,
) async {
  final GoalsRepository repository = ref.watch(goalsRepositoryProvider);
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final List<ActionDayConfirmation> confirmations = await repository
      .listActionDayConfirmations(day: today);
  final Set<String> uniqueActionIds = <String>{};
  for (final ActionDayConfirmation confirmation in confirmations) {
    final DateTime local = confirmation.confirmedAt.toLocal();
    final DateTime confirmationDay = DateTime(
      local.year,
      local.month,
      local.day,
    );
    if (confirmationDay != today) continue;
    uniqueActionIds.add(confirmation.actionId);
  }
  return uniqueActionIds.length;
});

enum GoalPriorityResult {
  prioritized,
  unprioritized,
  limitReached,
  completedGoalNotAllowed,
}

class GoalsController extends AsyncNotifier<List<Goal>> {
  late final GoalsRepository _repository;

  @override
  Future<List<Goal>> build() async {
    _repository = ref.read(goalsRepositoryProvider);
    List<Goal> goals = await _repository.listGoals();
    final bool hadNormalizationChanges = await _normalizePriorityRanks(goals);
    if (hadNormalizationChanges) {
      goals = await _repository.listGoals();
    }
    return goals;
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.listGoals);
  }

  Future<void> createGoal({required String title, String? description}) async {
    await _repository.createGoal(title: title, description: description);
    await _refreshGoals();
  }

  Future<void> updateGoal({
    required Goal goal,
    required String title,
    String? description,
  }) async {
    final String? trimmedDescription = description?.trim();
    final bool shouldClearDescription =
        description != null && trimmedDescription!.isEmpty;

    final Goal updatedGoal = goal.copyWith(
      title: title,
      description: shouldClearDescription ? null : trimmedDescription,
      clearDescription: shouldClearDescription,
      updatedAt: DateTime.now(),
    );
    await _repository.updateGoal(updatedGoal);
    await _refreshGoals();
  }

  Future<void> deleteGoal(String goalId) async {
    await _repository.deleteGoal(goalId);
    ref.invalidate(focusStreakProvider);
    ref.invalidate(dailyCompletedActionsProvider);
    await _refreshGoals();
  }

  Future<GoalPriorityResult> togglePriority(Goal goal) async {
    final List<Goal> goals = await _repository.listGoals();
    final Goal target = goals.firstWhere(
      (item) => item.id == goal.id,
      orElse: () => goal,
    );
    final DateTime now = DateTime.now();

    if (target.priorityRank != null) {
      await _repository.updateGoal(
        target.copyWith(clearPriority: true, updatedAt: now),
      );
      await _refreshGoals();
      return GoalPriorityResult.unprioritized;
    }

    if (target.progress >= 1) {
      return GoalPriorityResult.completedGoalNotAllowed;
    }

    final List<Goal> prioritized = goals
        .where((item) => item.priorityRank != null && item.progress < 1)
        .toList(growable: false);
    if (prioritized.length >= 3) {
      return GoalPriorityResult.limitReached;
    }

    final int nextRank = prioritized.length + 1;
    await _repository.updateGoal(
      target.copyWith(priorityRank: nextRank, updatedAt: now),
    );
    await _refreshGoals();
    return GoalPriorityResult.prioritized;
  }

  Future<void> _refreshGoals() async {
    List<Goal> goals = await _repository.listGoals();
    final bool hadNormalizationChanges = await _normalizePriorityRanks(goals);
    if (hadNormalizationChanges) {
      goals = await _repository.listGoals();
    }
    state = AsyncData(goals);
  }

  Future<bool> _normalizePriorityRanks(List<Goal> goals) async {
    bool changed = false;

    // Completed goals cannot keep priority rank.
    for (final Goal goal in goals) {
      if (goal.priorityRank == null || goal.progress < 1) continue;
      final Goal withoutPriority = goal.copyWith(
        clearPriority: true,
        updatedAt: DateTime.now(),
      );
      await _repository.updateGoal(withoutPriority);
      changed = true;
    }

    final List<Goal> prioritized =
        goals
            .where((goal) => goal.priorityRank != null && goal.progress < 1)
            .toList()
          ..sort((a, b) {
            final int byRank = a.priorityRank!.compareTo(b.priorityRank!);
            if (byRank != 0) return byRank;
            return a.createdAt.compareTo(b.createdAt);
          });

    for (int i = 0; i < prioritized.length; i++) {
      final Goal goal = prioritized[i];
      final int? expectedRank = i < 3 ? i + 1 : null;
      if (goal.priorityRank == expectedRank) continue;

      final Goal normalized = goal.copyWith(
        priorityRank: expectedRank,
        clearPriority: expectedRank == null,
        updatedAt: DateTime.now(),
      );
      await _repository.updateGoal(normalized);
      changed = true;
    }

    return changed;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quebrando_metas/features/goals/data/local_goals_repository.dart';
import 'package:quebrando_metas/features/goals/data/goals_repository.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';

final LocalGoalsRepository _localGoalsRepository = LocalGoalsRepository();

final Provider<GoalsRepository> goalsRepositoryProvider =
    Provider<GoalsRepository>((ref) {
  return _localGoalsRepository;
});

final AsyncNotifierProvider<GoalsController, List<Goal>> goalsControllerProvider =
    AsyncNotifierProvider<GoalsController, List<Goal>>(GoalsController.new);

class GoalsController extends AsyncNotifier<List<Goal>> {
  late final GoalsRepository _repository;

  @override
  Future<List<Goal>> build() async {
    _repository = ref.read(goalsRepositoryProvider);
    return _repository.listGoals();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.listGoals);
  }

  Future<void> createGoal({
    required String title,
    String? description,
  }) async {
    await _repository.createGoal(
      title: title,
      description: description,
    );
    final List<Goal> goals = await _repository.listGoals();
    state = AsyncData(goals);
  }

  Future<void> updateGoal({
    required Goal goal,
    required String title,
    String? description,
  }) async {
    final Goal updatedGoal = goal.copyWith(
      title: title,
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      updatedAt: DateTime.now(),
    );
    await _repository.updateGoal(updatedGoal);
    final List<Goal> goals = await _repository.listGoals();
    state = AsyncData(goals);
  }

  Future<void> deleteGoal(String goalId) async {
    await _repository.deleteGoal(goalId);
    final List<Goal> goals = await _repository.listGoals();
    state = AsyncData(goals);
  }
}

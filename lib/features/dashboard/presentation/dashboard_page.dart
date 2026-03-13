import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quebrando_metas/app/router.dart';
import 'package:quebrando_metas/core/widgets/main_bottom_nav.dart';
import 'package:quebrando_metas/core/widgets/theme_drawer.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  static const Key createGoalFabKey = Key('create-goal-fab');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Goal>> goalsAsync = ref.watch(
      goalsControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Quebrando Metas')),
      drawer: const ThemeDrawer(),
      body: goalsAsync.when(
        data: (goals) => _DashboardContent(goals: goals),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _DashboardContent(goals: <Goal>[]),
      ),
      floatingActionButton: FloatingActionButton(
        key: createGoalFabKey,
        onPressed: () => context.push(AppRoutes.createGoal),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: const NearNavBarFabLocation(),
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.goals});

  final List<Goal> goals;

  @override
  Widget build(BuildContext context) {
    final int completedGoalsCount = goals
        .where((goal) => goal.progress >= 1)
        .length;
    final List<Goal> activeGoals = goals
        .where((goal) => goal.progress < 1)
        .toList();
    final double averageProgress = _averageProgress(activeGoals);
    final List<Goal> prioritizedGoals =
        activeGoals.where((goal) => goal.priorityRank != null).toList()
          ..sort((a, b) => a.priorityRank!.compareTo(b.priorityRank!));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _HeaderSummary(
          completedGoalsCount: completedGoalsCount,
          activeGoalsCount: activeGoals.length,
          averageProgress: averageProgress,
        ),
        const SizedBox(height: 16),
        _PriorityGoalsSection(prioritizedGoals: prioritizedGoals),
      ],
    );
  }
}

class _HeaderSummary extends StatelessWidget {
  const _HeaderSummary({
    required this.completedGoalsCount,
    required this.activeGoalsCount,
    required this.averageProgress,
  });

  final int completedGoalsCount;
  final int activeGoalsCount;
  final double averageProgress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ola!', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Metas concluidas: $completedGoalsCount'),
            const SizedBox(height: 4),
            Text('Voce tem $activeGoalsCount metas ativas'),
            const SizedBox(height: 4),
            Text(
              'Progresso medio: ${(averageProgress * 100).toStringAsFixed(0)}%',
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityGoalsSection extends StatelessWidget {
  const _PriorityGoalsSection({required this.prioritizedGoals});

  final List<Goal> prioritizedGoals;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Continue de onde parou',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (prioritizedGoals.isEmpty) ...[
              const Text('Defina uma meta como prioridade.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go(AppRoutes.goals),
                child: const Text('Escolher prioridade'),
              ),
            ] else ...[
              ...prioritizedGoals
                  .take(3)
                  .map(
                    (goal) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prioridade ${goal.priorityRank}: ${goal.title}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Progresso: ${(goal.progress * 100).toStringAsFixed(0)}%',
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () => context.pushNamed(
                              'goal-actions',
                              pathParameters: {'goalId': goal.id},
                            ),
                            child: const Text('Continuar'),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

double _averageProgress(List<Goal> activeGoals) {
  if (activeGoals.isEmpty) return 0;

  final double sum = activeGoals.fold<double>(
    0,
    (previousValue, goal) => previousValue + goal.progress,
  );

  return sum / activeGoals.length;
}

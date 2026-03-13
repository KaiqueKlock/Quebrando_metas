import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quebrando_metas/app/router.dart';
import 'package:quebrando_metas/core/widgets/main_bottom_nav.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Goal>> goalsAsync = ref.watch(goalsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quebrando Metas'),
      ),
      body: goalsAsync.when(
        data: (goals) => _DashboardContent(goals: goals),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _DashboardContent(goals: <Goal>[]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createGoal),
        icon: const Icon(Icons.add),
        label: const Text('Nova Meta'),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.goals});

  final List<Goal> goals;

  @override
  Widget build(BuildContext context) {
    final int completedGoalsCount = goals.where((goal) => goal.progress >= 1).length;
    final List<Goal> activeGoals = goals.where((goal) => goal.progress < 1).toList();
    final double averageProgress = _averageProgress(activeGoals);
    final Goal? highlightedGoal = activeGoals.isEmpty ? null : activeGoals.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _HeaderSummary(
          completedGoalsCount: completedGoalsCount,
          activeGoalsCount: activeGoals.length,
          averageProgress: averageProgress,
        ),
        const SizedBox(height: 16),
        if (highlightedGoal != null)
          _ContinueCard(goal: highlightedGoal)
        else
          const _EmptyDashboardCard(),
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
            Text(
              'Ola!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Metas concluidas: $completedGoalsCount'),
            const SizedBox(height: 4),
            Text('Voce tem $activeGoalsCount metas ativas'),
            const SizedBox(height: 4),
            Text('Progresso medio: ${(averageProgress * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.goal});

  final Goal goal;

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
            Text('Meta: ${goal.title}'),
            const SizedBox(height: 4),
            Text('Progresso: ${(goal.progress * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 4),
            const Text('Proxima acao: Defina sua primeira acao'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.pushNamed(
                'goal-actions',
                pathParameters: {'goalId': goal.id},
              ),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDashboardCard extends StatelessWidget {
  const _EmptyDashboardCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Voce ainda nao tem metas ativas. Crie uma nova meta para comecar.',
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
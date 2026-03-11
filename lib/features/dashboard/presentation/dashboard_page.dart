import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quebrando_metas/app/router.dart';
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
        error: (_, __) => Center(
          child: FilledButton(
            onPressed: () => ref.read(goalsControllerProvider.notifier).reload(),
            child: const Text('Tentar novamente'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createGoal),
        icon: const Icon(Icons.add),
        label: const Text('Nova Meta'),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.goals});

  final List<Goal> goals;

  @override
  Widget build(BuildContext context) {
    final double averageProgress = _averageProgress(goals);
    final Goal? highlightedGoal = goals.isEmpty ? null : goals.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _HeaderSummary(
          activeGoalsCount: goals.length,
          averageProgress: averageProgress,
        ),
        const SizedBox(height: 16),
        if (highlightedGoal != null) _ContinueCard(goal: highlightedGoal),
        const SizedBox(height: 20),
        _GoalsSection(goals: goals),
      ],
    );
  }
}

class _HeaderSummary extends StatelessWidget {
  const _HeaderSummary({
    required this.activeGoalsCount,
    required this.averageProgress,
  });

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
              onPressed: () {},
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({required this.goals});

  final List<Goal> goals;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhuma meta ativa. Toque em "Nova Meta" para comecar.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suas metas',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...goals.map((goal) => _GoalCard(goal: goal)),
      ],
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      context.pushNamed('edit-goal', extra: goal);
                      return;
                    }

                    if (value == 'delete') {
                      await ref
                          .read(goalsControllerProvider.notifier)
                          .deleteGoal(goal.id);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Editar'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Excluir'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: goal.progress),
            const SizedBox(height: 8),
            Text('${(goal.progress * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 4),
            Text('${goal.completedActions} de ${goal.totalActions} acoes concluidas'),
            const SizedBox(height: 4),
            const Text('Proxima acao: Defina sua primeira acao'),
          ],
        ),
      ),
    );
  }
}

double _averageProgress(List<Goal> goals) {
  if (goals.isEmpty) return 0;

  final double sum = goals.fold<double>(
    0,
    (previousValue, goal) => previousValue + goal.progress,
  );

  return sum / goals.length;
}

import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<HomeGoalViewData> goals = _mockGoals;
    final double averageProgress = _averageProgress(goals);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quebrando Metas'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _HeaderSummary(
            activeGoalsCount: goals.length,
            averageProgress: averageProgress,
          ),
          const SizedBox(height: 16),
          if (goals.isNotEmpty) _ContinueCard(goal: goals.first),
          const SizedBox(height: 20),
          _GoalsSection(goals: goals),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Nova Meta'),
      ),
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

  final HomeGoalViewData goal;

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
            Text('Meta: ${goal.name}'),
            const SizedBox(height: 4),
            Text('Progresso: ${(goal.progress * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 4),
            Text('Proxima acao: ${goal.nextAction}'),
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

  final List<HomeGoalViewData> goals;

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

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final HomeGoalViewData goal;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: goal.progress),
            const SizedBox(height: 8),
            Text('${(goal.progress * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 4),
            Text('${goal.completedActions} de ${goal.totalActions} acoes concluidas'),
            const SizedBox(height: 4),
            Text('Proxima acao: ${goal.nextAction}'),
          ],
        ),
      ),
    );
  }
}

class HomeGoalViewData {
  const HomeGoalViewData({
    required this.name,
    required this.completedActions,
    required this.totalActions,
    required this.nextAction,
  }) : progress = totalActions == 0 ? 0 : completedActions / totalActions;

  final String name;
  final int completedActions;
  final int totalActions;
  final String nextAction;
  final double progress;
}

double _averageProgress(List<HomeGoalViewData> goals) {
  if (goals.isEmpty) return 0;

  final double sum = goals.fold<double>(
    0,
    (previousValue, goal) => previousValue + goal.progress,
  );

  return sum / goals.length;
}

const List<HomeGoalViewData> _mockGoals = [
  HomeGoalViewData(
    name: 'Emagrecer',
    completedActions: 2,
    totalActions: 6,
    nextAction: 'Treinar 3x essa semana',
  ),
  HomeGoalViewData(
    name: 'Estudar Flutter',
    completedActions: 4,
    totalActions: 8,
    nextAction: 'Revisar estado com Riverpod',
  ),
  HomeGoalViewData(
    name: 'Ler mais livros',
    completedActions: 1,
    totalActions: 5,
    nextAction: 'Ler 20 paginas hoje',
  ),
  HomeGoalViewData(
    name: 'Organizar financas',
    completedActions: 3,
    totalActions: 5,
    nextAction: 'Categorizar gastos da semana',
  ),
];

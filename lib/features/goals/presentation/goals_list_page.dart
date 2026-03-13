import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quebrando_metas/app/router.dart';
import 'package:quebrando_metas/core/widgets/main_bottom_nav.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';

class GoalsListPage extends ConsumerWidget {
  const GoalsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Goal>> goalsAsync = ref.watch(goalsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suas Metas'),
      ),
      body: goalsAsync.when(
        data: (goals) => _GoalsListContent(goals: goals),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _GoalsListContent(goals: <Goal>[]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createGoal),
        icon: const Icon(Icons.add),
        label: const Text('Nova Meta'),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
    );
  }
}

class _GoalsListContent extends StatelessWidget {
  const _GoalsListContent({required this.goals});

  final List<Goal> goals;

  @override
  Widget build(BuildContext context) {
    final List<Goal> activeGoals = goals.where((goal) => goal.progress < 1).toList();
    final List<Goal> completedGoals = goals.where((goal) => goal.progress >= 1).toList();
    final List<Goal> orderedGoals = [...activeGoals, ...completedGoals];

    if (orderedGoals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhuma meta criada ainda. Toque em "Nova Meta" para comecar.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        ...orderedGoals.map((goal) => _GoalCard(goal: goal)),
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
      child: InkWell(
        onTap: () => context.pushNamed(
          'goal-actions',
          pathParameters: {'goalId': goal.id},
        ),
        borderRadius: BorderRadius.circular(12),
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
                        context.pushNamed(
                          'edit-goal',
                          pathParameters: {'goalId': goal.id},
                        );
                        return;
                      }

                      if (value == 'delete') {
                        await ref.read(goalsControllerProvider.notifier).deleteGoal(goal.id);
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
              const Text('Toque para gerenciar acoes'),
            ],
          ),
        ),
      ),
    );
  }
}

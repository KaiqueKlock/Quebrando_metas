import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quebrando_metas/app/router.dart';
import 'package:quebrando_metas/core/widgets/main_bottom_nav.dart';
import 'package:quebrando_metas/core/widgets/theme_drawer.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/presentation/goal_form_dialog.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';

class GoalsListPage extends ConsumerWidget {
  const GoalsListPage({super.key});

  static const Key createGoalFabKey = Key('create-goal-fab');
  static const Key goalsListScrollKey = Key('goals-list-scroll');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Goal>> goalsAsync = ref.watch(
      goalsControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Suas Metas')),
      drawer: const ThemeDrawer(),
      body: goalsAsync.when(
        data: (goals) => _GoalsListContent(goals: goals),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _GoalsListContent(goals: <Goal>[]),
      ),
      floatingActionButton: FloatingActionButton(
        key: createGoalFabKey,
        onPressed: () async {
          await showGoalFormDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: const NearNavBarFabLocation(),
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
    );
  }
}

class _GoalsListContent extends StatelessWidget {
  const _GoalsListContent({required this.goals});

  final List<Goal> goals;

  @override
  Widget build(BuildContext context) {
    final bool isCompact = _isCompactLayout(context);
    final double horizontalPadding = isCompact ? 12 : 16;
    final double topPadding = isCompact ? 8 : 12;
    final double headerBottomSpacing = isCompact ? 10 : 12;
    final double listBottomPadding = isCompact ? 88 : 96;
    final int completedGoalsCount = goals
        .where((goal) => goal.progress >= 1)
        .length;
    final List<Goal> activeGoals = goals
        .where((goal) => goal.progress < 1)
        .toList();
    final double averageProgress = _averageProgress(activeGoals);
    final List<Goal> prioritizedActiveGoals =
        activeGoals.where((goal) => goal.priorityRank != null).toList()
          ..sort((a, b) => a.priorityRank!.compareTo(b.priorityRank!));
    final List<Goal> regularActiveGoals = activeGoals
        .where((goal) => goal.priorityRank == null)
        .toList();
    final List<Goal> completedGoals = goals
        .where((goal) => goal.progress >= 1)
        .toList();
    final List<Goal> orderedGoals = [
      ...prioritizedActiveGoals,
      ...regularActiveGoals,
      ...completedGoals,
    ];

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            headerBottomSpacing,
          ),
          child: _HeaderSummary(
            completedGoalsCount: completedGoalsCount,
            activeGoalsCount: activeGoals.length,
            averageProgress: averageProgress,
            isCompact: isCompact,
          ),
        ),
        Expanded(
          child: orderedGoals.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: isCompact ? 20 : 28,
                      horizontal: isCompact ? 16 : 24,
                    ),
                    child: const Text(
                      'Nenhuma meta criada ainda. Toque em "Nova Meta" para comecar.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  key: GoalsListPage.goalsListScrollKey,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    listBottomPadding,
                  ),
                  children: orderedGoals
                      .map((goal) => _GoalCard(goal: goal, isCompact: isCompact))
                      .toList(),
                ),
          )
      ],
    );
  }
}

class _HeaderSummary extends StatelessWidget {
  const _HeaderSummary({
    required this.completedGoalsCount,
    required this.activeGoalsCount,
    required this.averageProgress,
    required this.isCompact,
  });

  final int completedGoalsCount;
  final int activeGoalsCount;
  final double averageProgress;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: isCompact ? 2 : 3,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
        side: BorderSide(color: colorScheme.primary, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ola!',
              style: isCompact
                  ? Theme.of(context).textTheme.titleLarge
                  : Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: isCompact ? 6 : 8),
            Text(
              'Metas concluidas: $completedGoalsCount',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Voce tem $activeGoalsCount metas ativas',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Progresso medio: ${(averageProgress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal, required this.isCompact});

  final Goal goal;
  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.only(bottom: isCompact ? 10 : 12),
      child: InkWell(
        onTap: () => context.pushNamed(
          'goal-actions',
          pathParameters: {'goalId': goal.id},
        ),
        borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
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
                  IconButton(
                    onPressed: () async {
                      final GoalPriorityResult result = await ref
                          .read(goalsControllerProvider.notifier)
                          .togglePriority(goal);
                      if (!context.mounted) return;
                      final String message;
                      switch (result) {
                        case GoalPriorityResult.prioritized:
                          message = 'Meta adicionada as prioridades.';
                          break;
                        case GoalPriorityResult.unprioritized:
                          message = 'Meta removida das prioridades.';
                          break;
                        case GoalPriorityResult.limitReached:
                          message = 'Voce pode priorizar no maximo 3 metas.';
                          break;
                        case GoalPriorityResult.completedGoalNotAllowed:
                          message =
                              'Apenas metas ativas podem ser priorizadas.';
                          break;
                      }
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    },
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      reverseDuration: const Duration(milliseconds: 140),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        goal.priorityRank == null
                            ? Icons.star_border
                            : Icons.star,
                        key: ValueKey<bool>(goal.priorityRank != null),
                        color: goal.priorityRank == null
                            ? null
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    tooltip: goal.priorityRank == null
                        ? 'Definir prioridade'
                        : 'Remover prioridade',
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await showGoalFormDialog(context, ref, goal: goal);
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
              SizedBox(height: isCompact ? 6 : 8),
              if (goal.priorityRank != null)
                Padding(
                  padding: EdgeInsets.only(bottom: isCompact ? 4 : 6),
                  child: Text(
                    'Prioridade ${goal.priorityRank}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              SizedBox(height: isCompact ? 1 : 2),
              LinearProgressIndicator(value: goal.progress),
              SizedBox(height: isCompact ? 6 : 8),
              Text('${(goal.progress * 100).toStringAsFixed(0)}%'),
              const SizedBox(height: 4),
              Text(
                '${goal.completedActions} de ${goal.totalActions} acoes concluidas',
              ),
              const SizedBox(height: 4),
              const Text('Toque para gerenciar acoes'),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isCompactLayout(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return size.width <= 380 || size.height <= 700;
}

double _averageProgress(List<Goal> activeGoals) {
  if (activeGoals.isEmpty) return 0;

  final double sum = activeGoals.fold<double>(
    0,
    (previousValue, goal) => previousValue + goal.progress,
  );

  return sum / activeGoals.length;
}

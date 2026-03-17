import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quebrando_metas/app/router.dart';
import 'package:quebrando_metas/core/widgets/main_bottom_nav.dart';
import 'package:quebrando_metas/core/widgets/theme_drawer.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/presentation/goal_form_dialog.dart';
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
        onPressed: () async {
          await showGoalFormDialog(context, ref);
        },
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
    final bool isCompact = _isCompactLayout(context);
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
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 16,
        isCompact ? 8 : 12,
        isCompact ? 12 : 16,
        isCompact ? 88 : 96,
      ),
      children: [
        _HeaderSummary(
          completedGoalsCount: completedGoalsCount,
          activeGoalsCount: activeGoals.length,
          averageProgress: averageProgress,
          isCompact: isCompact,
        ),
        SizedBox(height: isCompact ? 12 : 16),
        _PriorityGoalsSection(
          prioritizedGoals: prioritizedGoals,
          isCompact: isCompact,
        ),
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
    return Card(
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
  const _PriorityGoalsSection({
    required this.prioritizedGoals,
    required this.isCompact,
  });

  static const Key contentSwitcherKey = Key('priority-content-switcher');

  final List<Goal> prioritizedGoals;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Continue de onde parou',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: isCompact ? 10 : 12),
            AnimatedSwitcher(
              key: contentSwitcherKey,
              duration: const Duration(milliseconds: 200),
              reverseDuration: const Duration(milliseconds: 160),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final Animation<double> fade = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                final Animation<Offset> slide =
                    Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    );

                return FadeTransition(
                  opacity: fade,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: prioritizedGoals.isEmpty
                  ? _EmptyPriorityState(key: const ValueKey('priority-empty'))
                  : _PriorityGoalsList(
                      key: ValueKey<String>(
                        prioritizedGoals
                            .take(3)
                            .map((goal) => '${goal.id}:${goal.priorityRank}')
                            .join('|'),
                      ),
                      prioritizedGoals: prioritizedGoals,
                      isCompact: isCompact,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPriorityState extends StatelessWidget {
  const _EmptyPriorityState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Defina uma meta como prioridade.'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => context.go(AppRoutes.goals),
          child: const Text('Escolher prioridade'),
        ),
      ],
    );
  }
}

class _PriorityGoalsList extends StatelessWidget {
  const _PriorityGoalsList({
    super.key,
    required this.prioritizedGoals,
    required this.isCompact,
  });

  final List<Goal> prioritizedGoals;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: prioritizedGoals
          .take(3)
          .map(
            (goal) => Padding(
              padding: EdgeInsets.only(bottom: isCompact ? 10 : 12),
              child: SizedBox(
                width: double.infinity,
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
                    SizedBox(height: isCompact ? 6 : 8),
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
          )
          .toList(),
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

bool _isCompactLayout(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return size.width <= 380 || size.height <= 700;
}

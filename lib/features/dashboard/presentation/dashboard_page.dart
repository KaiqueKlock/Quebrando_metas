import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quebrando_metas/app/onboarding_status.dart';
import 'package:quebrando_metas/core/widgets/theme_drawer.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/presentation/goal_form_dialog.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  static const Key createGoalFabKey = Key('create-goal-fab');
  static const Key goalsListScrollKey = Key('goals-list-scroll');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Goal>> goalsAsync = ref.watch(
      goalsControllerProvider,
    );
    final bool compactAppBarTitle = MediaQuery.sizeOf(context).width < 320;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          compactAppBarTitle ? 'Metas' : 'Quebrando Metas',
          overflow: TextOverflow.ellipsis,
        ),
      ),
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
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.goals});

  final List<Goal> goals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isCompact = _isCompactLayout(context);
    final AsyncValue<int> streakAsync = ref.watch(focusStreakProvider);
    final int currentStreak = streakAsync.maybeWhen(
      data: (value) => value,
      orElse: () => 0,
    );

    final List<Goal> activeGoals = goals
        .where((goal) => goal.progress < 1)
        .toList();
    final List<Goal> prioritizedGoals =
        activeGoals.where((goal) => goal.priorityRank != null).toList()
          ..sort((a, b) => a.priorityRank!.compareTo(b.priorityRank!));
    final List<Goal> continueGoals = _selectContinueGoals(prioritizedGoals);

    final List<Goal> regularActiveGoals = activeGoals
        .where((goal) => goal.priorityRank == null)
        .toList();
    final List<Goal> completedGoals = goals
        .where((goal) => goal.progress >= 1)
        .toList();
    final List<Goal> orderedGoals = <Goal>[
      ...prioritizedGoals,
      ...regularActiveGoals,
      ...completedGoals,
    ];

    final int totalFocusMinutes = goals.fold<int>(
      0,
      (sum, goal) => sum + goal.totalFocusMinutes,
    );
    final double investedHours = totalFocusMinutes / 60;
    return ListView(
      key: DashboardPage.goalsListScrollKey,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 16,
        isCompact ? 10 : 14,
        isCompact ? 12 : 16,
        isCompact ? 92 : 100,
      ),
      children: [
        AnimatedBuilder(
          animation: OnboardingStatus.instance,
          builder: (context, _) => _HeaderSection(
            greeting: OnboardingStatus.instance.greetingMessage(),
            currentStreak: currentStreak,
            investedHours: investedHours,
            isCompact: isCompact,
          ),
        ),
        SizedBox(height: isCompact ? 12 : 16),
        _ContinueSection(goals: continueGoals, isCompact: isCompact),
        SizedBox(height: isCompact ? 18 : 22),
        Text(
          'Suas Metas',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: isCompact ? 10 : 12),
        if (orderedGoals.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 14 : 16),
              child: const Text(
                'Nenhuma meta criada ainda. Toque em + para começar.',
              ),
            ),
          )
        else
          ...orderedGoals.map(
            (goal) => _GoalListCard(goal: goal, isCompact: isCompact),
          ),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.greeting,
    required this.currentStreak,
    required this.investedHours,
    required this.isCompact,
  });

  final String greeting;
  final int currentStreak;
  final double investedHours;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              greeting,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.waving_hand_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        SizedBox(height: isCompact ? 10 : 12),
        Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            _SummaryChip(
              icon: Icons.local_fire_department_outlined,
              label: _formatDays(currentStreak),
            ),
            _SummaryChip(
              icon: Icons.timer_outlined,
              label: '${investedHours.toStringAsFixed(1)} horas',
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _ContinueSection extends ConsumerWidget {
  const _ContinueSection({required this.goals, required this.isCompact});

  static const Key contentSwitcherKey = Key('priority-content-switcher');
  static const Key continueGoalTitleKey = Key('continue-goal-title');

  final List<Goal> goals;
  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (goals.isEmpty) {
      return Card(
        key: contentSwitcherKey,
        color: colors.primaryContainer,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 12 : 14,
            isCompact ? 14 : 16,
            isCompact ? 12 : 14,
            isCompact ? 14 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONTINUE DE ONDE PAROU',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text('Defina uma meta como prioridade.'),
            ],
          ),
        ),
      );
    }

    return Card(
      key: contentSwitcherKey,
      color: colors.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 12 : 14,
          isCompact ? 14 : 16,
          isCompact ? 12 : 14,
          isCompact ? 14 : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'CONTINUE DE ONDE PAROU',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.spa_outlined, color: colors.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List<Widget>.generate(goals.length, (index) {
              final Goal currentGoal = goals[index];
              return Padding(
                key: ValueKey<String>('continue-goal-item-${currentGoal.id}'),
                padding: EdgeInsets.only(
                  top: 6,
                  bottom: index == goals.length - 1 ? 0 : 6,
                ),
                child: _ContinueGoalItem(
                  goal: currentGoal,
                  isCompact: isCompact,
                  isFirst: index == 0,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ContinueGoalItem extends ConsumerWidget {
  const _ContinueGoalItem({
    required this.goal,
    required this.isCompact,
    required this.isFirst,
  });

  final Goal goal;
  final bool isCompact;
  final bool isFirst;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal.title,
            key: isFirst ? _ContinueSection.continueGoalTitleKey : null,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text('${(goal.progress * 100).toStringAsFixed(0)}%'),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 6,
              backgroundColor: colors.surface.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<ActionItem>>(
            future: ref.read(goalsRepositoryProvider).listActions(goal.id),
            builder: (context, snapshot) {
              final List<ActionItem> actions =
                  snapshot.data ?? const <ActionItem>[];
              final ActionItem? nextAction = _nextActionForContinueCard(
                actions,
              );
              final String nextActionTitle =
                  nextAction?.title ?? 'Sem ação pendente';

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Próxima ação',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nextActionTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => context.pushNamed(
                      'goal-actions',
                      pathParameters: {'goalId': goal.id},
                    ),
                    child: const Text('Continuar'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GoalListCard extends ConsumerWidget {
  const _GoalListCard({required this.goal, required this.isCompact});

  final Goal goal;
  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double progressPercent = goal.progress * 100;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      key: ValueKey<String>('goal-card-${goal.id}'),
      margin: EdgeInsets.only(bottom: isCompact ? 10 : 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.pushNamed(
          'goal-actions',
          pathParameters: {'goalId': goal.id},
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 12 : 14,
            isCompact ? 12 : 14,
            isCompact ? 8 : 10,
            isCompact ? 8 : 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${progressPercent.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                        softWrap: false,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${progressPercent.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodyMedium,
                      softWrap: false,
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 8,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool useCompactActionsRow =
                      isCompact ||
                      !constraints.maxWidth.isFinite ||
                      constraints.maxWidth < 300;
                  final Widget priorityButton = IconButton(
                    key: ValueKey<String>('toggle-priority-${goal.id}'),
                    onPressed: () async {
                      final GoalPriorityResult result = await ref
                          .read(goalsControllerProvider.notifier)
                          .togglePriority(goal);
                      if (!context.mounted) return;

                      final String message;
                      switch (result) {
                        case GoalPriorityResult.prioritized:
                          message = 'Meta adicionada às prioridades.';
                          break;
                        case GoalPriorityResult.unprioritized:
                          message = 'Meta removida das prioridades.';
                          break;
                        case GoalPriorityResult.limitReached:
                          message = 'Você pode priorizar no máximo 3 metas.';
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
                    tooltip: goal.priorityRank == null
                        ? 'Definir prioridade'
                        : 'Remover prioridade',
                    icon: Icon(
                      goal.priorityRank == null
                          ? Icons.star_border
                          : Icons.star,
                      color: goal.priorityRank == null ? null : colors.primary,
                    ),
                  );
                  final Widget menuButton = PopupMenuButton<String>(
                    key: ValueKey<String>('goal-menu-${goal.id}'),
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
                  );
                  final Widget actionCountText = Text(
                    '${goal.completedActions} de ${goal.totalActions} ações',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );

                  if (useCompactActionsRow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        actionCountText,
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [priorityButton, menuButton],
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: actionCountText),
                      priorityButton,
                      menuButton,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDays(int days) {
  if (days == 1) return '1 dia seguido';
  return '$days dias seguidos';
}

bool _isCompactLayout(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return size.width <= 380 || size.height <= 700;
}

// Regra atual da Home:
// o card "Continue de onde parou" exibe ate 3 metas prioritarias,
// em ordem de priorityRank.
List<Goal> _selectContinueGoals(List<Goal> prioritizedGoals) {
  if (prioritizedGoals.isEmpty) return const <Goal>[];
  return prioritizedGoals.take(3).toList(growable: false);
}

// Regra atual da "Próxima ação":
// usa a ação pendente com menor tempo de foco acumulado.
// Em empate, usa a de menor order.
ActionItem? _nextActionForContinueCard(List<ActionItem> actions) {
  ActionItem? selected;
  for (final ActionItem action in actions) {
    if (action.isCompleted) continue;
    if (selected == null) {
      selected = action;
      continue;
    }

    final bool hasLowerFocus =
        action.totalFocusMinutes < selected.totalFocusMinutes;
    final bool sameFocusAndLowerOrder =
        action.totalFocusMinutes == selected.totalFocusMinutes &&
        action.order < selected.order;
    if (hasLowerFocus || sameFocusAndLowerOrder) {
      selected = action;
    }
  }
  return selected;
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';
import 'package:quebrando_metas/features/goals/domain/focus_streak_calculator.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/domain/title_validator.dart';
import 'package:quebrando_metas/features/goals/presentation/goal_actions_controller.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';

class GoalActionsPage extends ConsumerStatefulWidget {
  const GoalActionsPage({super.key, required this.goalId});

  final String goalId;
  static const Key startFocusButtonKey = Key('start-focus-button');

  @override
  ConsumerState<GoalActionsPage> createState() => _GoalActionsPageState();
}

class _GoalActionsPageState extends ConsumerState<GoalActionsPage> {
  String? _selectedActionId;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Goal>> goalsAsync = ref.watch(
      goalsControllerProvider,
    );
    final Goal? goal = ref.watch(goalByIdProvider(widget.goalId));
    final AsyncValue<List<ActionItem>> actionsAsync = ref.watch(
      goalActionsControllerProvider(widget.goalId),
    );

    if (goalsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (goal == null) {
      return const Scaffold(body: Center(child: Text('Meta nao encontrada.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Meta')),
      body: actionsAsync.when(
        data: (actions) {
          final ActionItem? selectedAction = _findSelectedAction(actions);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              _GoalInfoSection(goal: goal),
              const SizedBox(height: 12),
              _GoalProgressCard(goal: goal),
              const SizedBox(height: 12),
              _GoalMetricsSection(goal: goal),
              const SizedBox(height: 18),
              Text(
                'Acoes da meta',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (actions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nenhuma acao cadastrada para esta meta.'),
                  ),
                )
              else
                ...actions.map(
                  (action) => _ActionTile(
                    action: action,
                    isSelectedForFocus: action.id == _selectedActionId,
                    onSwipeCompletion: (value) => _toggleActionCompletion(
                      action: action,
                      isCompleted: value,
                    ),
                    onSelectForFocus: action.isCompleted
                        ? null
                        : () {
                            setState(() {
                              _selectedActionId = action.id == _selectedActionId
                                  ? null
                                  : action.id;
                            });
                          },
                    onEdit: () => _editAction(action),
                    onDelete: () => _deleteAction(action),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erro ao carregar acoes.')),
      ),
      bottomNavigationBar: actionsAsync.maybeWhen(
        data: (actions) {
          final ActionItem? selectedAction = _findSelectedAction(actions);
          final bool canStartFocus =
              selectedAction != null && !selectedAction.isCompleted;
          return SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: FilledButton.icon(
              key: GoalActionsPage.startFocusButtonKey,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              onPressed: canStartFocus
                  ? () => _startFocusFlow(goal: goal, action: selectedAction)
                  : null,
              icon: const Icon(Icons.timer_outlined),
              label: Text(
                canStartFocus ? 'Iniciar foco' : 'Selecione uma acao para foco',
              ),
            ),
          );
        },
        orElse: () => null,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createAction,
        child: const Icon(Icons.add),
      ),
    );
  }

  ActionItem? _findSelectedAction(List<ActionItem> actions) {
    if (_selectedActionId == null) return null;
    for (final ActionItem action in actions) {
      if (action.id == _selectedActionId) return action;
    }
    return null;
  }

  Future<void> _toggleActionCompletion({
    required ActionItem action,
    required bool isCompleted,
  }) async {
    try {
      final ToggleActionResult result = await ref
          .read(goalActionsControllerProvider(widget.goalId).notifier)
          .toggleAction(
            goalId: widget.goalId,
            action: action,
            isCompleted: isCompleted,
          );
      if (!mounted) return;

      if (result == ToggleActionResult.blockedNoFocusTime) {
        _showMessage(context, 'Sem tempo gasto na acao.');
        return;
      }

      if (isCompleted && action.id == _selectedActionId) {
        setState(() {
          _selectedActionId = null;
        });
      }
    } catch (_) {
      if (mounted) {
        _showError(context, 'Nao foi possivel atualizar a acao.');
      }
    }
  }

  Future<void> _createAction() async {
    final String? title = await _showActionDialog(context, title: 'Nova acao');
    if (title == null) return;

    try {
      await ref
          .read(goalActionsControllerProvider(widget.goalId).notifier)
          .createAction(goalId: widget.goalId, title: title);
    } catch (_) {
      if (mounted) {
        _showError(context, 'Nao foi possivel criar a acao.');
      }
    }
  }

  Future<void> _editAction(ActionItem action) async {
    final String? updatedTitle = await _showActionDialog(
      context,
      title: 'Editar acao',
      initialValue: action.title,
    );
    if (updatedTitle == null) return;

    try {
      await ref
          .read(goalActionsControllerProvider(widget.goalId).notifier)
          .updateAction(
            goalId: widget.goalId,
            action: action,
            title: updatedTitle,
          );
    } catch (_) {
      if (mounted) {
        _showError(context, 'Nao foi possivel editar a acao.');
      }
    }
  }

  Future<void> _deleteAction(ActionItem action) async {
    if (action.id == _selectedActionId) {
      setState(() {
        _selectedActionId = null;
      });
    }

    try {
      await ref
          .read(goalActionsControllerProvider(widget.goalId).notifier)
          .deleteAction(goalId: widget.goalId, actionId: action.id);
    } catch (_) {
      if (mounted) {
        _showError(context, 'Nao foi possivel excluir a acao.');
      }
    }
  }

  Future<void> _startFocusFlow({
    required Goal goal,
    required ActionItem action,
  }) async {
    final int? durationMinutes = await _showFocusDurationPicker(context);
    if (!mounted || durationMinutes == null) return;

    final GoalActionsController controller = ref.read(
      goalActionsControllerProvider(widget.goalId).notifier,
    );

    late final FocusSession session;
    try {
      session = await controller.startFocusSession(
        goalId: widget.goalId,
        actionId: action.id,
        durationMinutes: durationMinutes,
      );
    } catch (_) {
      if (mounted) {
        _showError(context, 'Nao foi possivel iniciar o foco.');
      }
      return;
    }

    if (!mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => _FocusTimerPage(
          actionTitle: action.title,
          goalTitle: goal.title,
          durationMinutes: durationMinutes,
          sessionStartedAt: session.startedAt,
          onCompleted: (elapsedMinutes) => controller.completeFocusSession(
            session,
            elapsedMinutes: elapsedMinutes,
          ),
          onCanceled: (elapsedMinutes) => controller.cancelFocusSession(
            session,
            elapsedMinutes: elapsedMinutes,
          ),
        ),
      ),
    );
  }

  Future<int?> _showFocusDurationPicker(BuildContext context) {
    return showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escolha a duracao do foco',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [15, 30, 60]
                      .map((minutes) => _FocusDurationButton(minutes: minutes))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _showActionDialog(
    BuildContext context, {
    required String title,
    String initialValue = '',
  }) async {
    final TextEditingController controller = TextEditingController(
      text: initialValue,
    );
    String? errorText;

    return showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: TextField(
                controller: controller,
                autofocus: true,
                maxLength: TitleValidator.maxLength,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(TitleValidator.maxLength),
                ],
                decoration: InputDecoration(
                  labelText: 'Titulo da acao',
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    try {
                      final String value = TitleValidator.validate(
                        controller.text,
                      );
                      Navigator.of(context).pop(value);
                    } on FormatException catch (error) {
                      setState(() {
                        errorText = error.message;
                      });
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GoalProgressCard extends StatelessWidget {
  const _GoalProgressCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progresso da meta',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      minHeight: 10,
                      backgroundColor: colors.surface.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${(goal.progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalInfoSection extends StatelessWidget {
  const _GoalInfoSection({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final String description =
        (goal.description == null || goal.description!.trim().isEmpty)
        ? 'Sem descricao para esta meta.'
        : goal.description!.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Descricao da meta',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text(description),
          ],
        ),
      ),
    );
  }
}

class _GoalMetricsSection extends ConsumerWidget {
  const _GoalMetricsSection({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Tempo total',
            value: _formatMinutes(goal.totalFocusMinutes),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FutureBuilder<int>(
            future: _loadGoalStreak(ref, goal.id),
            builder: (context, snapshot) {
              final int streak = snapshot.data ?? 0;
              return _MetricCard(
                title: 'Sequencia',
                value: _formatDays(streak),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<int> _loadGoalStreak(WidgetRef ref, String goalId) async {
    final List<FocusSession> sessions = await ref
        .read(goalsRepositoryProvider)
        .listFocusSessions(goalId: goalId);
    return FocusStreakCalculator.currentStreakFromSessions(
      sessions,
      now: DateTime.now(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.action,
    required this.isSelectedForFocus,
    required this.onSwipeCompletion,
    required this.onSelectForFocus,
    required this.onEdit,
    required this.onDelete,
  });

  final ActionItem action;
  final bool isSelectedForFocus;
  final Future<void> Function(bool isCompleted) onSwipeCompletion;
  final VoidCallback? onSelectForFocus;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final bool canComplete = !action.isCompleted;
    final DismissDirection swipeDirection = canComplete
        ? DismissDirection.startToEnd
        : DismissDirection.endToStart;

    return Dismissible(
      key: ValueKey<String>('action-swipe-${action.id}'),
      direction: swipeDirection,
      confirmDismiss: (direction) async {
        final bool shouldComplete = direction == DismissDirection.startToEnd;
        await onSwipeCompletion(shouldComplete);
        return false;
      },
      background: _SwipeActionBackground(
        alignment: Alignment.centerLeft,
        color: Colors.green.shade600,
        icon: Icons.check_circle_outline,
        label: 'Concluir acao',
      ),
      secondaryBackground: _SwipeActionBackground(
        alignment: Alignment.centerRight,
        color: Colors.orange.shade700,
        icon: Icons.undo,
        label: 'Reabrir acao',
      ),
      child: Card(
        key: ValueKey<String>('action-card-${action.id}'),
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          key: ValueKey<String>('action-tile-${action.id}'),
          selected: isSelectedForFocus,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          leading: IconButton(
            key: ValueKey<String>(_legacySelectFocusKey(action.id)),
            tooltip: action.isCompleted
                ? 'Foco indisponivel para acao concluida'
                : (isSelectedForFocus
                      ? 'Acao selecionada para foco'
                      : 'Selecionar para foco'),
            onPressed: onSelectForFocus,
            icon: Icon(
              action.isCompleted
                  ? Icons.check_circle
                  : (isSelectedForFocus
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked),
              color: action.isCompleted ? Colors.green.shade600 : null,
            ),
          ),
          title: Text(
            action.title,
            style: action.isCompleted
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tempo de foco: ${_formatMinutes(action.totalFocusMinutes)}',
              ),
              Text(action.isCompleted ? 'Concluida' : 'Pendente'),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                key: ValueKey<String>('action-menu-${action.id}'),
                onSelected: (choice) {
                  if (choice == 'edit') {
                    onEdit();
                    return;
                  }
                  if (choice == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(value: 'edit', child: Text('Editar')),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Excluir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeActionBackground extends StatelessWidget {
  const _SwipeActionBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _FocusDurationButton extends StatelessWidget {
  const _FocusDurationButton({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: ValueKey<String>('focus-duration-$minutes'),
      onPressed: () => Navigator.of(context).pop(minutes),
      child: Text('$minutes min'),
    );
  }
}

class _FocusTimerPage extends StatefulWidget {
  const _FocusTimerPage({
    required this.actionTitle,
    required this.goalTitle,
    required this.durationMinutes,
    required this.sessionStartedAt,
    this.onCompleted,
    this.onCanceled,
  });

  final String actionTitle;
  final String goalTitle;
  final int durationMinutes;
  final DateTime sessionStartedAt;
  final Future<int> Function(int elapsedMinutes)? onCompleted;
  final Future<int> Function(int elapsedMinutes)? onCanceled;

  @override
  State<_FocusTimerPage> createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<_FocusTimerPage>
    with WidgetsBindingObserver {
  late int _remainingSeconds;
  late int _durationSeconds;
  late DateTime _expectedEndAt;
  Timer? _timer;
  bool _completed = false;
  bool _busy = false;
  int _completedMinutes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _durationSeconds = widget.durationMinutes * 60;
    _expectedEndAt = widget.sessionStartedAt.add(
      Duration(seconds: _durationSeconds),
    );
    _remainingSeconds = _durationSeconds;
    _syncRemainingTimeFromClock(now: DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    if (_remainingSeconds == 0) {
      unawaited(_handleCompleted());
    }
  }

  void _onTick(Timer timer) {
    if (_completed || _busy) return;
    if (_remainingSeconds <= 1) {
      setState(() {
        _remainingSeconds = 0;
      });
      unawaited(_handleCompleted());
      return;
    }

    setState(() {
      _remainingSeconds -= 1;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncRemainingTimeFromClock(now: DateTime.now());
    }
  }

  void _syncRemainingTimeFromClock({required DateTime now}) {
    if (_completed || _busy) return;
    final int updatedRemaining = _computeRemainingSeconds(now: now);
    if (updatedRemaining <= 0) {
      if (_remainingSeconds != 0) {
        setState(() {
          _remainingSeconds = 0;
        });
      }
      unawaited(_handleCompleted());
      return;
    }

    final int reducedRemaining = updatedRemaining < _remainingSeconds
        ? updatedRemaining
        : _remainingSeconds;
    if (_remainingSeconds != reducedRemaining) {
      setState(() {
        _remainingSeconds = reducedRemaining;
      });
    }
  }

  Future<void> _handleCompleted() async {
    if (_completed || _busy) return;
    _timer?.cancel();
    final int elapsedMinutes = _elapsedMinutes();
    setState(() {
      _remainingSeconds = 0;
      _busy = true;
    });
    int completedMinutes = elapsedMinutes;
    if (widget.onCompleted != null) {
      completedMinutes = await widget.onCompleted!(elapsedMinutes);
    }
    if (!mounted) return;
    setState(() {
      _completed = true;
      _busy = false;
      _completedMinutes = completedMinutes;
    });
  }

  Future<void> _cancelFocus() async {
    if (_completed || _busy) return;
    _timer?.cancel();
    final int elapsedMinutes = _elapsedMinutes();
    setState(() {
      _busy = true;
    });
    if (widget.onCanceled != null) {
      await widget.onCanceled!(elapsedMinutes);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Modo foco'),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meta: ${widget.goalTitle}'),
                      const SizedBox(height: 4),
                      Text('Acao: ${widget.actionTitle}'),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          _formatDuration(_remainingSeconds),
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_completed) ...[
                        const Text('Foco concluido!'),
                        const SizedBox(height: 4),
                        Text('Tempo gasto: $_completedMinutes min'),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _completed
              ? FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                )
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : _cancelFocus,
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy ? null : _handleCompleted,
                        child: const Text('Concluir agora'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int _computeRemainingSeconds({required DateTime now}) {
    final int remaining = _expectedEndAt.difference(now).inSeconds;
    if (remaining <= 0) return 0;
    return remaining;
  }

  int _elapsedMinutes() {
    final int elapsedSeconds = _durationSeconds - _remainingSeconds;
    if (elapsedSeconds <= 0) return 0;
    return elapsedSeconds ~/ 60;
  }
}

String _formatMinutes(int totalMinutes) {
  if (totalMinutes < 60) return '${totalMinutes}min';
  final int hours = totalMinutes ~/ 60;
  final int minutes = totalMinutes % 60;
  if (minutes == 0) return '${hours}h';
  return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
}

String _formatDays(int days) {
  if (days == 1) return '1 dia';
  return '$days dias';
}

String _legacySelectFocusKey(String actionId) {
  final String normalized = actionId.startsWith('action-')
      ? actionId.substring('action-'.length)
      : actionId;
  return 'select-focus-action-$normalized';
}

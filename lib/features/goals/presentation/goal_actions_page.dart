import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';
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
      return const Scaffold(body: Center(child: Text('Meta não encontrada.')));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Ações: ${goal.title}')),
      body: actionsAsync.when(
        data: (actions) {
          final ActionItem? selectedAction = _findSelectedAction(actions);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              _GoalDescriptionSection(description: goal.description),
              const SizedBox(height: 12),
              if (actions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nenhuma ação cadastrada para esta meta.'),
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
        error: (_, __) => const Center(child: Text('Erro ao carregar ações.')),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAction,
        icon: const Icon(Icons.add),
        label: const Text('Nova Ação'),
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
        _showError(context, 'Não foi possível atualizar a ação.');
      }
    }
  }

  Future<void> _createAction() async {
    final String? title = await _showActionDialog(context, title: 'Nova ação');
    if (title == null) return;

    try {
      await ref
          .read(goalActionsControllerProvider(widget.goalId).notifier)
          .createAction(goalId: widget.goalId, title: title);
    } catch (_) {
      if (mounted) {
        _showError(context, 'Não foi possível criar a ação.');
      }
    }
  }

  Future<void> _editAction(ActionItem action) async {
    final String? updatedTitle = await _showActionDialog(
      context,
      title: 'Editar ação',
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
        _showError(context, 'Não foi possível editar a ação.');
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
        _showError(context, 'Não foi possível excluir a ação.');
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
        _showError(context, 'Não foi possível iniciar o foco.');
      }
      return;
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FocusTimerDialog(
        actionTitle: action.title,
        goalTitle: goal.title,
        durationMinutes: durationMinutes,
        onCompleted: (elapsedMinutes) => controller.completeFocusSession(
          session,
          elapsedMinutes: elapsedMinutes,
        ),
        onCanceled: () => controller.cancelFocusSession(session),
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
                  children: const [15, 25, 45]
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
                  labelText: 'Titulo da ação',
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

  String _formatMinutes(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}min';
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
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
        child: ListTile(
          key: ValueKey<String>('action-tile-${action.id}'),
          selected: isSelectedForFocus,
          leading: IconButton(
            key: ValueKey<String>('select-focus-${action.id}'),
            tooltip: action.isCompleted
                ? 'Foco indisponivel para acao concluida'
                : (isSelectedForFocus
                      ? 'Acao selecionada para foco'
                      : 'Selecionar para foco'),
            onPressed: onSelectForFocus,
            icon: Icon(
              isSelectedForFocus
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
          ),
          title: Text(
            action.title,
            style: action.isCompleted
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          subtitle: Text(
            'Tempo de foco: ${_formatMinutes(action.totalFocusMinutes)}',
          ),
          trailing: PopupMenuButton<String>(
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
              PopupMenuItem<String>(value: 'delete', child: Text('Excluir')),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMinutes(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}min';
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
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

class _FocusTimerDialog extends StatefulWidget {
  const _FocusTimerDialog({
    required this.actionTitle,
    required this.goalTitle,
    required this.durationMinutes,
    this.onCompleted,
    this.onCanceled,
  });

  final String actionTitle;
  final String goalTitle;
  final int durationMinutes;
  final Future<int> Function(int elapsedMinutes)? onCompleted;
  final Future<void> Function()? onCanceled;

  @override
  State<_FocusTimerDialog> createState() => _FocusTimerDialogState();
}

class _FocusTimerDialogState extends State<_FocusTimerDialog> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _completed = false;
  bool _busy = false;
  int _completedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer timer) {
    if (_remainingSeconds <= 1) {
      _remainingSeconds = 0;
      _handleCompleted();
      return;
    }
    setState(() {
      _remainingSeconds -= 1;
    });
  }

  Future<void> _handleCompleted() async {
    if (_completed || _busy) return;
    _timer?.cancel();
    final int elapsedMinutes = _elapsedMinutes(_remainingSeconds);
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
    setState(() {
      _busy = true;
    });
    if (widget.onCanceled != null) {
      await widget.onCanceled!();
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modo foco'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Meta: ${widget.goalTitle}'),
            const SizedBox(height: 4),
            Text('Acao: ${widget.actionTitle}'),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _formatDuration(_remainingSeconds),
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            if (_completed) ...[
              const SizedBox(height: 12),
              const Text('Foco concluido!'),
              const SizedBox(height: 4),
              Text('Tempo gasto: $_completedMinutes min'),
            ],
          ],
        ),
      ),
      actions: [
        if (!_completed)
          TextButton(
            onPressed: _busy ? null : _cancelFocus,
            child: const Text('Cancelar'),
          ),
        FilledButton(
          onPressed: _completed
              ? () => Navigator.of(context).pop()
              : (_busy ? null : _handleCompleted),
          child: Text(_completed ? 'Fechar' : 'Concluir agora'),
        ),
      ],
    );
  }

  String _formatDuration(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int _elapsedMinutes(int remainingSeconds) {
    final int durationSeconds = widget.durationMinutes * 60;
    final int elapsedSeconds = durationSeconds - remainingSeconds;
    if (elapsedSeconds <= 0) return 0;
    return elapsedSeconds ~/ 60;
  }
}

class _GoalDescriptionSection extends StatelessWidget {
  const _GoalDescriptionSection({required this.description});

  final String? description;

  @override
  Widget build(BuildContext context) {
    final String descriptionText =
        (description == null || description!.trim().isEmpty)
        ? 'Sem descrição para esta meta.'
        : description!.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descrição da meta',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(descriptionText),
          ],
        ),
      ),
    );
  }
}

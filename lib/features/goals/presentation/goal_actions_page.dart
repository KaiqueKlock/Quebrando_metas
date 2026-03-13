import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/domain/title_validator.dart';
import 'package:quebrando_metas/features/goals/presentation/goal_actions_controller.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';

class GoalActionsPage extends ConsumerWidget {
  const GoalActionsPage({
    super.key,
    required this.goalId,
  });

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Goal>> goalsAsync = ref.watch(goalsControllerProvider);
    final Goal? goal = ref.watch(goalByIdProvider(goalId));
    final AsyncValue<List<ActionItem>> actionsAsync =
        ref.watch(goalActionsControllerProvider(goalId));

    if (goalsAsync.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (goal == null) {
      return const Scaffold(
        body: Center(
          child: Text('Meta nao encontrada.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Ações: ${goal.title}'),
      ),
      body: actionsAsync.when(
        data: (actions) {
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
                  (action) => CheckboxListTile(
                    title: Text(action.title),
                    value: action.isCompleted,
                    onChanged: (value) async {
                      if (value == null) return;
                      try {
                        await ref
                            .read(goalActionsControllerProvider(goalId).notifier)
                            .toggleAction(
                              goalId: goalId,
                              action: action,
                              isCompleted: value,
                            );
                      } catch (_) {
                        _showError(context, 'Nao foi possivel atualizar a ação.');
                      }
                    },
                    secondary: PopupMenuButton<String>(
                      onSelected: (choice) async {
                        if (choice == 'edit') {
                          final String? updatedTitle = await _showActionDialog(
                            context,
                            title: 'Editar ação',
                            initialValue: action.title,
                          );
                          if (updatedTitle == null) return;

                          try {
                            await ref
                                .read(goalActionsControllerProvider(goalId).notifier)
                                .updateAction(
                                  goalId: goalId,
                                  action: action,
                                  title: updatedTitle,
                                );
                          } catch (_) {
                            _showError(context, 'Nao foi possivel editar a ação.');
                          }
                        }

                        if (choice == 'delete') {
                          try {
                            await ref
                                .read(goalActionsControllerProvider(goalId).notifier)
                                .deleteAction(
                                  goalId: goalId,
                                  actionId: action.id,
                                );
                          } catch (_) {
                            _showError(context, 'Nao foi possivel excluir a ação.');
                          }
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
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erro ao carregar ações.')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final String? title = await _showActionDialog(
            context,
            title: 'Nova ação',
          );
          if (title == null) return;

          try {
            await ref.read(goalActionsControllerProvider(goalId).notifier).createAction(
                  goalId: goalId,
                  title: title,
                );
          } catch (_) {
            _showError(context, 'Nao foi possivel criar a ação.');
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Ação'),
      ),
    );
  }

  Future<String?> _showActionDialog(
    BuildContext context, {
    required String title,
    String initialValue = '',
  }) async {
    final TextEditingController controller = TextEditingController(text: initialValue);
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
                      final String value = TitleValidator.validate(controller.text);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _GoalDescriptionSection extends StatelessWidget {
  const _GoalDescriptionSection({required this.description});

  final String? description;

  @override
  Widget build(BuildContext context) {
    final String descriptionText =
        (description == null || description!.trim().isEmpty)
            ? 'Sem descricao para esta meta.'
            : description!.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descricao da meta',
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

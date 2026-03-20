import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/domain/title_validator.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';

Future<void> showGoalFormDialog(
  BuildContext context,
  WidgetRef ref, {
  Goal? goal,
}) async {
  const int descriptionMaxLength = 240;
  final TextEditingController titleController = TextEditingController(
    text: goal?.title ?? '',
  );
  final TextEditingController descriptionController = TextEditingController(
    text: goal?.description ?? '',
  );
  String? titleErrorText;
  bool isSaving = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          Future<void> onSave() async {
            try {
              final String validTitle = TitleValidator.validate(
                titleController.text,
              );
              setState(() {
                isSaving = true;
                titleErrorText = null;
              });

              if (goal == null) {
                await ref
                    .read(goalsControllerProvider.notifier)
                    .createGoal(
                      title: validTitle,
                      description: descriptionController.text,
                    );
              } else {
                await ref
                    .read(goalsControllerProvider.notifier)
                    .updateGoal(
                      goal: goal,
                      title: validTitle,
                      description: descriptionController.text,
                    );
              }

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            } on FormatException catch (error) {
              setState(() {
                titleErrorText = error.message;
              });
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nao foi possivel salvar a meta.'),
                  ),
                );
              }
            } finally {
              if (dialogContext.mounted) {
                setState(() {
                  isSaving = false;
                });
              }
            }
          }

          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            scrollable: true,
            title: Text(goal == null ? 'Nova Meta' : 'Editar Meta'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  maxLength: TitleValidator.maxLength,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      TitleValidator.maxLength,
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Titulo',
                    errorText: titleErrorText,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLength: descriptionMaxLength,
                  maxLines: 3,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(descriptionMaxLength),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Descricao (opcional)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop();
                      },
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: isSaving ? null : onSave,
                child: Text(isSaving ? 'Salvando...' : 'Salvar'),
              ),
            ],
          );
        },
      );
    },
  );
}

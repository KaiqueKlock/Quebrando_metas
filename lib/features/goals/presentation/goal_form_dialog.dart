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

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setState) {
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

              if (sheetContext.mounted) {
                Navigator.of(sheetContext).pop();
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
              if (sheetContext.mounted) {
                setState(() {
                  isSaving = false;
                });
              }
            }
          }

          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.92,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal == null ? 'Nova Meta' : 'Editar Meta',
                      style: Theme.of(sheetContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Defina um objetivo claro e pratico.',
                      style: Theme.of(sheetContext).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.of(sheetContext).pop(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: isSaving ? null : onSave,
                            child: Text(isSaving ? 'Salvando...' : 'Salvar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

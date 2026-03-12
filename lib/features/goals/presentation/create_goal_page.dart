import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/domain/title_validator.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';

class CreateGoalPage extends ConsumerStatefulWidget {
  const CreateGoalPage({
    super.key,
    this.goalId,
  });

  final String? goalId;

  bool get isEditMode => goalId != null;

  @override
  ConsumerState<CreateGoalPage> createState() => _CreateGoalPageState();
}

class _CreateGoalPageState extends ConsumerState<CreateGoalPage> {
  static const int _descriptionMaxLength = 240;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSaving = false;
  bool _prefilledFromGoal = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final Goal? currentGoal = widget.isEditMode
          ? ref.read(goalByIdProvider(widget.goalId!))
          : null;

      if (widget.isEditMode) {
        if (currentGoal == null) {
          _showError('Meta nao encontrada para edicao.');
          return;
        }
        await ref.read(goalsControllerProvider.notifier).updateGoal(
              goal: currentGoal,
              title: _titleController.text,
              description: _descriptionController.text,
            );
      } else {
        await ref.read(goalsControllerProvider.notifier).createGoal(
              title: _titleController.text,
              description: _descriptionController.text,
            );
      }
      if (!mounted) return;
      context.pop();
    } on FormatException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Nao foi possivel salvar a meta.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.isEditMode;
    final AsyncValue<List<Goal>> goalsAsync = ref.watch(goalsControllerProvider);
    final Goal? editingGoal = isEditMode ? ref.watch(goalByIdProvider(widget.goalId!)) : null;

    if (isEditMode && !_prefilledFromGoal && editingGoal != null) {
      _titleController.text = editingGoal.title;
      _descriptionController.text = editingGoal.description ?? '';
      _prefilledFromGoal = true;
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Editar Meta' : 'Nova Meta')),
      body: isEditMode && goalsAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : isEditMode && editingGoal == null
              ? const Center(child: Text('Meta nao encontrada.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titulo',
                      ),
                      maxLength: TitleValidator.maxLength,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(TitleValidator.maxLength),
                      ],
                      validator: (value) {
                        try {
                          TitleValidator.validate(value ?? '');
                          return null;
                        } on FormatException catch (error) {
                          return error.message;
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descricao (opcional)',
                      ),
                      maxLength: _descriptionMaxLength,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(_descriptionMaxLength),
                      ],
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _onSave,
                        child: Text(_isSaving ? 'Salvando...' : 'Salvar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

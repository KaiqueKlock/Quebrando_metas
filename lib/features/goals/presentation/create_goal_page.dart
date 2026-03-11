import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';

class CreateGoalPage extends ConsumerStatefulWidget {
  const CreateGoalPage({
    super.key,
    this.goal,
  });

  final Goal? goal;

  bool get isEditMode => goal != null;

  @override
  ConsumerState<CreateGoalPage> createState() => _CreateGoalPageState();
}

class _CreateGoalPageState extends ConsumerState<CreateGoalPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final Goal? goal = widget.goal;
    if (goal != null) {
      _titleController.text = goal.title;
      _descriptionController.text = goal.description ?? '';
    }
  }

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
      if (widget.isEditMode) {
        await ref.read(goalsControllerProvider.notifier).updateGoal(
              goal: widget.goal!,
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

    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Editar Meta' : 'Nova Meta')),
      body: Padding(
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
                maxLength: 80,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe um titulo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descricao (opcional)',
                ),
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
}

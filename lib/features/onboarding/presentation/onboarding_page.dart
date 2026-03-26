import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quebrando_metas/app/onboarding_status.dart';
import 'package:quebrando_metas/app/router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const int _maxNameLength = 30;

  late final TextEditingController _nameController;
  String? _nameError;
  bool _saving = false;

  bool get _canSubmit => !_saving && _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: OnboardingStatus.instance.displayName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      setState(() {
        _nameError = 'Digite seu nome para continuar.';
      });
      return;
    }

    setState(() {
      _nameError = null;
      _saving = true;
    });

    try {
      await OnboardingStatus.instance.setDisplayName(trimmedName);
      await OnboardingStatus.instance.setCompleted(true);
      if (!mounted) return;
      context.go(AppRoutes.dashboard);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel concluir o onboarding.'),
        ),
      );
      setState(() {
        _saving = false;
      });
    }
  }

  void _onNameChanged(String _) {
    if (_nameError != null) {
      setState(() {
        _nameError = null;
      });
      return;
    }

    if (_saving) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Boas-vindas')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Bem-vindo ao Quebrando Metas',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vamos configurar seu nome para personalizar a home.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      key: const Key('onboarding-name-input'),
                      controller: _nameController,
                      maxLength: _maxNameLength,
                      textInputAction: TextInputAction.done,
                      onChanged: _onNameChanged,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Seu nome',
                        hintText: 'Ex: Kaique',
                        errorText: _nameError,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Voce pode mudar isso depois nas configuracoes.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('onboarding-submit-button'),
                        onPressed: _canSubmit ? _submit : null,
                        child: Text(_saving ? 'Salvando...' : 'Comecar'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

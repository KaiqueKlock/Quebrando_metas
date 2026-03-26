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
          content: Text('Não foi possível concluir o onboarding.'),
        ),
      );
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Boas-vindas')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vamos personalizar sua experiência',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Como você gostaria de ser chamado?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              TextField(
                key: const Key('onboarding-name-input'),
                controller: _nameController,
                maxLength: _maxNameLength,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Seu nome',
                  hintText: 'Ex: Kaique',
                  errorText: _nameError,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('onboarding-submit-button'),
                  onPressed: _saving ? null : _submit,
                  child: Text(_saving ? 'Salvando...' : 'Começar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

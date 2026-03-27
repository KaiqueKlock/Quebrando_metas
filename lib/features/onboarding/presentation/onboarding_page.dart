import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quebrando_metas/app/onboarding_status.dart';
import 'package:quebrando_metas/app/router.dart';

enum _OnboardingStep { name, howItWorks }

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const int _maxNameLength = 30;

  late final TextEditingController _nameController;
  _OnboardingStep _step = _OnboardingStep.name;
  String? _nameError;
  bool _busy = false;

  bool get _canContinueName => !_busy && _nameController.text.trim().isNotEmpty;

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

  Future<void> _continueFromName() async {
    final String trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      setState(() {
        _nameError = 'Digite seu nome para continuar.';
      });
      return;
    }

    setState(() {
      _nameError = null;
      _busy = true;
    });

    try {
      await OnboardingStatus.instance.setDisplayName(trimmedName);
      if (!mounted) return;
      setState(() {
        _step = _OnboardingStep.howItWorks;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar seu nome.')),
      );
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() {
      _busy = true;
    });

    try {
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
        _busy = false;
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

    if (_busy) return;
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
                child: _step == _OnboardingStep.name
                    ? _NameStep(
                        controller: _nameController,
                        nameError: _nameError,
                        maxNameLength: _maxNameLength,
                        canContinue: _canContinueName,
                        busy: _busy,
                        onNameChanged: _onNameChanged,
                        onContinue: _continueFromName,
                      )
                    : _HowItWorksStep(
                        displayName: OnboardingStatus.instance.displayName,
                        busy: _busy,
                        onBack: _busy
                            ? null
                            : () => setState(() {
                                _step = _OnboardingStep.name;
                              }),
                        onFinish: _finishOnboarding,
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({
    required this.controller,
    required this.nameError,
    required this.maxNameLength,
    required this.canContinue,
    required this.busy,
    required this.onNameChanged,
    required this.onContinue,
  });

  final TextEditingController controller;
  final String? nameError;
  final int maxNameLength;
  final bool canContinue;
  final bool busy;
  final ValueChanged<String> onNameChanged;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('onboarding-name-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Bem-vindo ao Quebrando Metas',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Antes de começar, como você gostaria de ser chamado?',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        TextField(
          key: const Key('onboarding-name-input'),
          controller: controller,
          maxLength: maxNameLength,
          textInputAction: TextInputAction.done,
          onChanged: onNameChanged,
          onSubmitted: (_) => onContinue(),
          decoration: InputDecoration(
            labelText: 'Seu nome',
            hintText: 'Ex: Kaique',
            errorText: nameError,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Você pode mudar isso depois nas configurações.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('onboarding-submit-button'),
            onPressed: canContinue ? onContinue : null,
            child: Text(busy ? 'Salvando...' : 'Continuar'),
          ),
        ),
      ],
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({
    required this.displayName,
    required this.busy,
    required this.onBack,
    required this.onFinish,
  });

  final String displayName;
  final bool busy;
  final VoidCallback? onBack;
  final Future<void> Function() onFinish;

  @override
  Widget build(BuildContext context) {
    final String normalizedName = displayName.trim();
    final String greeting = normalizedName.isEmpty
        ? 'Tudo pronto!'
        : 'Tudo pronto, $normalizedName!';

    return Column(
      key: const Key('onboarding-how-it-works-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            greeting,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Veja rapidamente como o app funciona:',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        const _HowItWorksItem(
          icon: Icons.flag_outlined,
          title: '1. Crie uma meta',
          description: 'Defina um objetivo claro para acompanhar sua evolução.',
        ),
        const SizedBox(height: 12),
        const _HowItWorksItem(
          icon: Icons.checklist_outlined,
          title: '2. Adicione ações',
          description: 'Quebre a meta em ações pequenas e práticas.',
        ),
        const SizedBox(height: 12),
        const _HowItWorksItem(
          icon: Icons.timer_outlined,
          title: '3. Use o modo foco',
          description: 'Registre tempo real investido em cada ação.',
        ),
        const SizedBox(height: 12),
        const _HowItWorksItem(
          icon: Icons.trending_up_outlined,
          title: '4. Acompanhe progresso e streak',
          description: 'Mantenha constância vendo sua evolução dia a dia.',
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('onboarding-back-button'),
                onPressed: onBack,
                child: const Text('Voltar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                key: const Key('onboarding-finish-button'),
                onPressed: busy ? null : onFinish,
                child: Text(busy ? 'Concluindo...' : 'Começar agora'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HowItWorksItem extends StatelessWidget {
  const _HowItWorksItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

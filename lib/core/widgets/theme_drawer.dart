import 'package:flutter/material.dart';
import 'package:quebrando_metas/app/onboarding_status.dart';
import 'package:quebrando_metas/app/theme/app_theme_settings.dart';

class ThemeDrawer extends StatelessWidget {
  const ThemeDrawer({super.key});

  static const Key toggleThemeKey = Key('toggle-theme-icon');
  static const Key editNameTileKey = Key('edit-name-tile');
  static const Key editNameInputKey = Key('edit-name-input');
  static const Key editNameSaveKey = Key('edit-name-save');

  @override
  Widget build(BuildContext context) {
    final AppThemeSettings settings = AppThemeSettings.instance;
    return Drawer(
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          final List<ThemeColorOption> colorOptions =
              AppThemeSettings.colorOptions;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: Text(
                    'Configurações',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    key: editNameTileKey,
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Alterar nome'),
                    onTap: () async {
                      final bool? didSave = await showDialog<bool>(
                        context: context,
                        builder: (context) => const _EditNameDialog(),
                      );
                      if (!context.mounted || didSave != true) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nome atualizado.')),
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      IconButton(
                        key: toggleThemeKey,
                        tooltip: settings.isDarkMode
                            ? 'Trocar para tema claro'
                            : 'Trocar para tema escuro',
                        onPressed: settings.toggleThemeMode,
                        iconSize: 30,
                        icon: Icon(
                          settings.isDarkMode
                              ? Icons.nightlight_round
                              : Icons.wb_sunny_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              ExpansionTile(
                title: const Text('Definir cor'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  if (colorOptions.isEmpty)
                    const Text('Nenhuma cor acessível disponível.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colorOptions.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final ThemeColorOption option = entry.value;
                        final bool isSelected =
                            settings.seedColor.value == option.color.value;
                        return ChoiceChip(
                          key: Key('theme-color-$index'),
                          label: Text(option.label),
                          selectedColor: option.color.withValues(alpha: 0.22),
                          avatar: CircleAvatar(
                            radius: 8,
                            backgroundColor: option.color,
                          ),
                          selected: isSelected,
                          onSelected: (_) =>
                              settings.setSeedColor(option.color),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog();

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  static const int _maxNameLength = 30;
  late final TextEditingController _controller;
  bool _saving = false;
  String? _error;

  String get _trimmedName => _controller.text.trim();
  bool get _canSave => !_saving && _trimmedName.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: OnboardingStatus.instance.displayName,
    );
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_error != null) {
      setState(() => _error = null);
      return;
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await OnboardingStatus.instance.setDisplayName(_trimmedName);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Não foi possível atualizar seu nome.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alterar nome'),
      content: TextField(
        key: ThemeDrawer.editNameInputKey,
        controller: _controller,
        maxLength: _maxNameLength,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          labelText: 'Seu nome',
          hintText: 'Ex: Kaique',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: ThemeDrawer.editNameSaveKey,
          onPressed: _canSave ? _save : null,
          child: Text(_saving ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}

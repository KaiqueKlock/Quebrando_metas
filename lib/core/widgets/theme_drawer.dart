import 'package:flutter/material.dart';
import 'package:quebrando_metas/app/theme/app_theme_settings.dart';

class ThemeDrawer extends StatelessWidget {
  const ThemeDrawer({super.key});

  static const Key toggleThemeKey = Key('toggle-theme-icon');

  @override
  Widget build(BuildContext context) {
    final AppThemeSettings settings = AppThemeSettings.instance;
    return Drawer(
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text('Configurações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              Column(
              
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    
                    children: [
                      SizedBox(width: 32),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppThemeSettings.colorOptions.map((option) {
                      final bool isSelected =
                          settings.seedColor.value == option.color.value;
                      return ChoiceChip(
                        label: Text(option.label),
                        selectedColor: option.color.withValues(alpha: 0.22),
                        avatar: CircleAvatar(
                          radius: 8,
                          backgroundColor: option.color,
                        ),
                        selected: isSelected,
                        onSelected: (_) => settings.setSeedColor(option.color),
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

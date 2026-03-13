import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quebrando_metas/app/theme/theme_contrast_audit.dart';

class ThemeColorOption {
  const ThemeColorOption({required this.label, required this.color});

  final String label;
  final Color color;
}

class AppThemeSettings extends ChangeNotifier {
  AppThemeSettings._();

  static final AppThemeSettings instance = AppThemeSettings._();

  static const String _boxName = 'app_settings_box';
  static const String _themeModeKey = 'theme_mode';
  static const String _themeColorKey = 'theme_color';

  static const List<ThemeColorOption> _allColorOptions = <ThemeColorOption>[
    ThemeColorOption(label: 'Azul', color: Colors.blue),
    ThemeColorOption(label: 'Verde', color: Colors.green),
    ThemeColorOption(label: 'Laranja', color: Colors.orange),
    ThemeColorOption(label: 'Vermelho', color: Colors.red),
    ThemeColorOption(label: 'Teal', color: Colors.teal),
  ];

  static final List<ThemeColorOption> colorOptions =
      List<ThemeColorOption>.unmodifiable(
        _allColorOptions.where(
          (option) => ThemeContrastAudit.isSeedColorAccessible(option.color),
        ),
      );

  ThemeMode _themeMode = ThemeMode.light;
  Color _seedColor = _defaultSeedColor;
  bool _storageAvailable = false;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> init() async {
    try {
      final Box box = await Hive.openBox(_boxName);
      _themeMode = _themeModeFromValue(box.get(_themeModeKey) as String?);
      _seedColor = _colorFromValue(box.get(_themeColorKey) as int?);
      _storageAvailable = true;
    } catch (_) {
      _storageAvailable = false;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == ThemeMode.system) {
      mode = ThemeMode.light;
    }
    if (_themeMode == mode) return;
    _themeMode = mode;
    if (_storageAvailable) {
      final Box box = await Hive.openBox(_boxName);
      await box.put(_themeModeKey, mode.name);
    }
    notifyListeners();
  }

  Future<void> toggleThemeMode() async {
    final ThemeMode nextMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }

  Future<void> setSeedColor(Color color) async {
    if (!_isAllowedSeedColor(color)) return;
    if (_seedColor.value == color.value) return;
    _seedColor = color;
    if (_storageAvailable) {
      final Box box = await Hive.openBox(_boxName);
      await box.put(_themeColorKey, color.value);
    }
    notifyListeners();
  }

  ThemeMode _themeModeFromValue(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.light;
    }
  }

  Color _colorFromValue(int? value) {
    if (value == null) return _defaultSeedColor;
    final Color storedColor = Color(value);
    if (_isAllowedSeedColor(storedColor)) return storedColor;
    return _defaultSeedColor;
  }

  static Color get _defaultSeedColor {
    if (colorOptions.isNotEmpty) return colorOptions.first.color;
    return Colors.blue;
  }

  bool _isAllowedSeedColor(Color color) {
    return colorOptions.any((option) => option.color.value == color.value);
  }
}

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppUsageSettings extends ChangeNotifier {
  AppUsageSettings._();

  static final AppUsageSettings instance = AppUsageSettings._();

  static const String _boxName = 'app_settings_box';
  static const String _focusModeEnabledKey = 'focus_mode_enabled';

  bool _focusModeEnabled = true;
  bool _storageAvailable = false;

  bool get isFocusModeEnabled => _focusModeEnabled;

  Future<void> init() async {
    try {
      final Box<dynamic> box = await Hive.openBox<dynamic>(_boxName);
      _focusModeEnabled = (box.get(_focusModeEnabledKey) as bool?) ?? true;
      _storageAvailable = true;
    } on Object {
      _storageAvailable = false;
      _focusModeEnabled = true;
    }
  }

  Future<void> setFocusModeEnabled(bool value) async {
    if (_focusModeEnabled == value) return;
    _focusModeEnabled = value;
    if (_storageAvailable) {
      final Box<dynamic> box = await Hive.openBox<dynamic>(_boxName);
      await box.put(_focusModeEnabledKey, value);
    }
    notifyListeners();
  }

  Future<void> toggleFocusModeEnabled() async {
    await setFocusModeEnabled(!isFocusModeEnabled);
  }
}

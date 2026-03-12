import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class OnboardingStatus extends ChangeNotifier {
  OnboardingStatus._();

  static final OnboardingStatus instance = OnboardingStatus._();

  static const String _boxName = 'app_settings_box';
  static const String _key = 'onboarding_completed';

  bool _hasCompletedOnboarding = true;

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  Future<void> init() async {
    final Box box = await Hive.openBox(_boxName);
    _hasCompletedOnboarding = (box.get(_key) as bool?) ?? true;
  }

  Future<void> setCompleted(bool value) async {
    if (_hasCompletedOnboarding == value) return;

    _hasCompletedOnboarding = value;
    final Box box = await Hive.openBox(_boxName);
    await box.put(_key, value);
    notifyListeners();
  }
}

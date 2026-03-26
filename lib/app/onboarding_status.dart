import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class OnboardingStatus extends ChangeNotifier {
  OnboardingStatus._();

  static final OnboardingStatus instance = OnboardingStatus._();

  static const String _boxName = 'app_settings_box';
  static const String _key = 'onboarding_completed';
  static const String _displayNameKey = 'display_name';
  static const String _greetingIndexKey = 'greeting_index';
  static const String _greetingLastChangedAtKey = 'greeting_last_changed_at';
  static const Duration _greetingRotationWindow = Duration(hours: 12);
  static const List<String> _greetings = <String>[
    'Olá',
    'Oi',
    'Bem vindo de volta',
    'Eai',
  ];

  bool _hasCompletedOnboarding = true;
  String _displayName = '';
  int _greetingIndex = 0;
  DateTime? _greetingLastChangedAt;

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  String get displayName => _displayName;

  String greetingMessage({DateTime? now}) {
    final String baseGreeting =
        _greetings[_normalizeGreetingIndex(_greetingIndex)];
    final String trimmedName = _displayName.trim();
    if (trimmedName.isEmpty) return '$baseGreeting!';
    return '$baseGreeting, $trimmedName!';
  }

  Future<void> init() async {
    final Box box = await Hive.openBox(_boxName);
    _hasCompletedOnboarding = (box.get(_key) as bool?) ?? true;
    _displayName = ((box.get(_displayNameKey) as String?) ?? '').trim();
    _greetingIndex = _normalizeGreetingIndex(
      _parseInt(box.get(_greetingIndexKey)),
    );
    _greetingLastChangedAt = _parseDateTime(box.get(_greetingLastChangedAtKey));

    await _maybeRotateGreeting(box, now: DateTime.now());
  }

  Future<void> setCompleted(bool value) async {
    if (_hasCompletedOnboarding == value) return;

    _hasCompletedOnboarding = value;
    final Box box = await Hive.openBox(_boxName);
    await box.put(_key, value);
    notifyListeners();
  }

  Future<void> setDisplayName(String value) async {
    final String normalized = value.trim();
    if (_displayName == normalized) return;

    _displayName = normalized;
    final Box box = await Hive.openBox(_boxName);
    if (normalized.isEmpty) {
      await box.delete(_displayNameKey);
    } else {
      await box.put(_displayNameKey, normalized);
    }
    notifyListeners();
  }

  Future<void> _maybeRotateGreeting(Box box, {required DateTime now}) async {
    if (_greetings.length < 2) return;

    final DateTime localNow = now.toLocal();
    final DateTime? lastChanged = _greetingLastChangedAt?.toLocal();
    if (lastChanged == null) {
      _greetingLastChangedAt = localNow;
      await box.put(
        _greetingLastChangedAtKey,
        _greetingLastChangedAt!.toIso8601String(),
      );
      await box.put(_greetingIndexKey, _normalizeGreetingIndex(_greetingIndex));
      return;
    }

    if (localNow.difference(lastChanged) < _greetingRotationWindow) {
      return;
    }

    final Random random = Random(localNow.millisecondsSinceEpoch);
    final bool shouldRotate = random.nextInt(100) < 40;

    _greetingLastChangedAt = localNow;
    await box.put(
      _greetingLastChangedAtKey,
      _greetingLastChangedAt!.toIso8601String(),
    );

    if (!shouldRotate) return;

    final int currentIndex = _normalizeGreetingIndex(_greetingIndex);
    final int jump = random.nextInt(_greetings.length - 1) + 1;
    _greetingIndex = (currentIndex + jump) % _greetings.length;
    await box.put(_greetingIndexKey, _greetingIndex);
  }

  int _normalizeGreetingIndex(int? index) {
    if (index == null || index < 0) return 0;
    return index % _greetings.length;
  }

  int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  DateTime? _parseDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

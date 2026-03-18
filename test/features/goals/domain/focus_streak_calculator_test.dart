import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';
import 'package:quebrando_metas/features/goals/domain/focus_streak_calculator.dart';

void main() {
  group('FocusStreakCalculator', () {
    test('returns zero when there are no focus starts', () {
      final int streak = FocusStreakCalculator.currentStreakFromSessions(
        const <FocusSession>[],
        now: DateTime(2026, 3, 18, 12),
      );

      expect(streak, 0);
    });

    test('counts unique consecutive days including today', () {
      final DateTime now = DateTime(2026, 3, 18, 20);
      final List<FocusSession> sessions = <FocusSession>[
        _sessionAt(DateTime(2026, 3, 18, 8)),
        _sessionAt(DateTime(2026, 3, 18, 19)), // duplicate day
        _sessionAt(DateTime(2026, 3, 17, 21)),
        _sessionAt(DateTime(2026, 3, 16, 7)),
      ];

      final int streak = FocusStreakCalculator.currentStreakFromSessions(
        sessions,
        now: now,
      );

      expect(streak, 3);
    });

    test('keeps streak when latest focus is yesterday', () {
      final DateTime now = DateTime(2026, 3, 18, 10);
      final List<FocusSession> sessions = <FocusSession>[
        _sessionAt(DateTime(2026, 3, 17, 23)),
        _sessionAt(DateTime(2026, 3, 16, 9)),
      ];

      final int streak = FocusStreakCalculator.currentStreakFromSessions(
        sessions,
        now: now,
      );

      expect(streak, 2);
    });

    test('resets streak when one full day is missed', () {
      final DateTime now = DateTime(2026, 3, 18, 12);
      final List<FocusSession> sessions = <FocusSession>[
        _sessionAt(DateTime(2026, 3, 16, 12)),
        _sessionAt(DateTime(2026, 3, 15, 12)),
      ];

      final int streak = FocusStreakCalculator.currentStreakFromSessions(
        sessions,
        now: now,
      );

      expect(streak, 0);
    });

    test('returns only today when there is a gap in the middle', () {
      final DateTime now = DateTime(2026, 3, 18, 12);
      final List<FocusSession> sessions = <FocusSession>[
        _sessionAt(DateTime(2026, 3, 18, 9)),
        _sessionAt(DateTime(2026, 3, 16, 9)),
      ];

      final int streak = FocusStreakCalculator.currentStreakFromSessions(
        sessions,
        now: now,
      );

      expect(streak, 1);
    });

    test('best streak uses longest historical sequence', () {
      final List<FocusSession> sessions = <FocusSession>[
        _sessionAt(DateTime(2026, 3, 10, 9)),
        _sessionAt(DateTime(2026, 3, 9, 9)),
        _sessionAt(DateTime(2026, 3, 8, 9)),
        _sessionAt(DateTime(2026, 3, 5, 9)),
        _sessionAt(DateTime(2026, 3, 4, 9)),
      ];

      final int best = FocusStreakCalculator.bestStreakFromSessions(sessions);

      expect(best, 3);
    });

    test('best streak ignores duplicate starts on same day', () {
      final List<FocusSession> sessions = <FocusSession>[
        _sessionAt(DateTime(2026, 3, 11, 8)),
        _sessionAt(DateTime(2026, 3, 11, 20)),
        _sessionAt(DateTime(2026, 3, 10, 9)),
      ];

      final int best = FocusStreakCalculator.bestStreakFromSessions(sessions);

      expect(best, 2);
    });

    test('current streak works with unsorted sessions and duplicate days', () {
      final DateTime now = DateTime(2026, 3, 18, 22);
      final List<FocusSession> sessions = <FocusSession>[
        _sessionAt(DateTime(2026, 3, 17, 10)),
        _sessionAt(DateTime(2026, 3, 18, 9)),
        _sessionAt(DateTime(2026, 3, 18, 20)),
        _sessionAt(DateTime(2026, 3, 16, 7)),
      ];

      final int streak = FocusStreakCalculator.currentStreakFromSessions(
        sessions,
        now: now,
      );

      expect(streak, 3);
    });

    test('best streak handles month boundary as consecutive days', () {
      final List<FocusSession> sessions = <FocusSession>[
        _sessionAt(DateTime(2026, 3, 1, 9)),
        _sessionAt(DateTime(2026, 2, 28, 9)),
        _sessionAt(DateTime(2026, 2, 27, 9)),
        _sessionAt(DateTime(2026, 2, 24, 9)),
      ];

      final int best = FocusStreakCalculator.bestStreakFromSessions(sessions);

      expect(best, 3);
    });

    test('best streak returns one when no days are consecutive', () {
      final List<FocusSession> sessions = <FocusSession>[
        _sessionAt(DateTime(2026, 3, 18, 9)),
        _sessionAt(DateTime(2026, 3, 16, 9)),
        _sessionAt(DateTime(2026, 3, 14, 9)),
      ];

      final int best = FocusStreakCalculator.bestStreakFromSessions(sessions);

      expect(best, 1);
    });
  });
}

FocusSession _sessionAt(DateTime startedAt) {
  final DateTime stamp = startedAt.add(const Duration(minutes: 1));
  return FocusSession(
    id: 'session-${startedAt.microsecondsSinceEpoch}',
    actionId: 'action-1',
    goalId: 'goal-1',
    startedAt: startedAt,
    endedAt: null,
    durationMinutes: 25,
    status: FocusSessionStatus.running,
    createdAt: stamp,
    updatedAt: stamp,
  );
}

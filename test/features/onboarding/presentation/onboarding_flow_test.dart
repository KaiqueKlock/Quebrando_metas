@Tags(['regression'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/app/onboarding_status.dart';
import 'package:quebrando_metas/app/router.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';
import 'package:quebrando_metas/main.dart';

import '../../../fakes/fake_in_memory_goals_repository.dart';

void main() {
  setUp(() {
    OnboardingStatus.instance.debugUseInMemoryMode(true);
    OnboardingStatus.instance.debugSeed(
      hasCompletedOnboarding: true,
      displayName: '',
      greetingIndex: 0,
    );
    AppRouter.router.go(AppRoutes.dashboard);
  });

  testWidgets('Redirects to onboarding when onboarding is pending', (
    WidgetTester tester,
  ) async {
    OnboardingStatus.instance.debugSeed(hasCompletedOnboarding: false);

    await _pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('Boas-vindas'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-name-step')), findsOneWidget);
    expect(find.byKey(const Key('onboarding-name-input')), findsOneWidget);
    expect(find.byKey(const Key('create-goal-fab')), findsNothing);
  });

  testWidgets('Completes onboarding and navigates to dashboard with name', (
    WidgetTester tester,
  ) async {
    OnboardingStatus.instance.debugSeed(
      hasCompletedOnboarding: false,
      displayName: '',
      greetingIndex: 0,
    );

    await _pumpApp(tester);
    await tester.pumpAndSettle();

    FilledButton submitButton = tester.widget<FilledButton>(
      find.byKey(const Key('onboarding-submit-button')),
    );
    expect(submitButton.onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('onboarding-name-input')),
      'Kaique',
    );
    await tester.pumpAndSettle();

    submitButton = tester.widget<FilledButton>(
      find.byKey(const Key('onboarding-submit-button')),
    );
    expect(submitButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('onboarding-submit-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('onboarding-how-it-works-step')),
      findsOneWidget,
    );
    expect(find.text('1. Crie uma meta'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-finish-button')));
    await tester.pumpAndSettle();

    expect(find.text('Quebrando Metas'), findsOneWidget);
    expect(find.textContaining('Kaique'), findsOneWidget);
    expect(OnboardingStatus.instance.hasCompletedOnboarding, isTrue);
    expect(OnboardingStatus.instance.displayName, 'Kaique');
  });

  testWidgets(
    'Shows validation when submitting empty name from keyboard action',
    (WidgetTester tester) async {
      OnboardingStatus.instance.debugSeed(hasCompletedOnboarding: false);

      await _pumpApp(tester);
      await tester.pumpAndSettle();

      final Finder input = find.byKey(const Key('onboarding-name-input'));
      await tester.tap(input);
      await tester.pumpAndSettle();

      await tester.showKeyboard(input);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Digite seu nome para continuar.'), findsOneWidget);
    },
  );

  testWidgets('Redirects away from onboarding route when already completed', (
    WidgetTester tester,
  ) async {
    OnboardingStatus.instance.debugSeed(
      hasCompletedOnboarding: true,
      displayName: 'Ana',
      greetingIndex: 0,
    );
    AppRouter.router.go(AppRoutes.onboarding);

    await _pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-name-input')), findsNothing);
    expect(find.text('Quebrando Metas'), findsOneWidget);
    expect(find.textContaining('Ana'), findsOneWidget);
  });

  testWidgets('Keeps onboarding usable after screen rotation', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    OnboardingStatus.instance.debugSeed(hasCompletedOnboarding: false);

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);

    await _pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-name-input')), findsOneWidget);
    expect(find.byKey(const Key('onboarding-submit-button')), findsOneWidget);

    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-name-input')), findsOneWidget);
    expect(find.byKey(const Key('onboarding-submit-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Keeps how-it-works step usable after rotation', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    OnboardingStatus.instance.debugSeed(hasCompletedOnboarding: false);

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);

    await _pumpApp(tester);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('onboarding-name-input')),
      'Kaique',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-submit-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('onboarding-how-it-works-step')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('onboarding-finish-button')), findsOneWidget);

    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('onboarding-how-it-works-step')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('onboarding-finish-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    MyApp(
      overrides: [
        goalsRepositoryProvider.overrideWithValue(
          FakeInMemoryGoalsRepository(),
        ),
      ],
    ),
  );
}

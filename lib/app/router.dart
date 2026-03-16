import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quebrando_metas/app/onboarding_status.dart';
import 'package:quebrando_metas/features/dashboard/presentation/dashboard_page.dart';
import 'package:quebrando_metas/features/goals/presentation/goal_actions_page.dart';
import 'package:quebrando_metas/features/goals/presentation/create_goal_page.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_list_page.dart';
import 'package:quebrando_metas/features/onboarding/presentation/onboarding_page.dart';

class AppRoutes {
  const AppRoutes._();

  static const String dashboard = '/';
  static const String goals = '/goals';
  static const String onboarding = '/onboarding';
  static const String createGoal = '/goals/new';
  static const String editGoal = '/goals/:goalId/edit';
  static const String goalActions = '/goals/:goalId/actions';
}

class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: OnboardingStatus.instance,
    redirect: (context, state) {
      final OnboardingStatus onboardingStatus = OnboardingStatus.instance;
      final bool isOnboardingRoute =
          state.matchedLocation == AppRoutes.onboarding;

      if (!onboardingStatus.hasCompletedOnboarding && !isOnboardingRoute) {
        return AppRoutes.onboarding;
      }

      if (onboardingStatus.hasCompletedOnboarding && isOnboardingRoute) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) => _buildTabTransitionPage(
          state: state,
          child: const DashboardPage(),
          slideFromRight: false,
        ),
      ),
      GoRoute(
        path: AppRoutes.goals,
        name: 'goals',
        pageBuilder: (context, state) => _buildTabTransitionPage(
          state: state,
          child: const GoalsListPage(),
          slideFromRight: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.createGoal,
        name: 'create-goal',
        builder: (context, state) => const CreateGoalPage(),
      ),
      GoRoute(
        path: AppRoutes.editGoal,
        name: 'edit-goal',
        builder: (context, state) =>
            CreateGoalPage(goalId: state.pathParameters['goalId']),
      ),
      GoRoute(
        path: AppRoutes.goalActions,
        name: 'goal-actions',
        builder: (context, state) =>
            GoalActionsPage(goalId: state.pathParameters['goalId'] ?? ''),
      ),
    ],
  );

  static CustomTransitionPage<void> _buildTabTransitionPage({
    required GoRouterState state,
    required Widget child,
    required bool slideFromRight,
  }) {
    final Offset beginOffset = slideFromRight
        ? const Offset(0.03, 0)
        : const Offset(-0.03, 0);

    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Animation<double> fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final Animation<Offset> slide =
            Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}

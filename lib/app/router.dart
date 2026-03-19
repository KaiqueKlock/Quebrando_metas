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
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.goals,
        name: 'goals',
        builder: (context, state) => const GoalsListPage(),
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
}

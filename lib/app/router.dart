import 'package:go_router/go_router.dart';
import 'package:quebrando_metas/features/dashboard/presentation/dashboard_page.dart';
import 'package:quebrando_metas/features/onboarding/presentation/onboarding_page.dart';

class AppRoutes {
  const AppRoutes._();

  static const String dashboard = '/';
  static const String onboarding = '/onboarding';
}

class AppRouter {
  const AppRouter._();

  static bool hasCompletedOnboarding = true;

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.dashboard,
    redirect: (context, state) {
      final bool isOnboardingRoute = state.matchedLocation == AppRoutes.onboarding;

      if (!hasCompletedOnboarding && !isOnboardingRoute) {
        return AppRoutes.onboarding;
      }

      if (hasCompletedOnboarding && isOnboardingRoute) {
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
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
    ],
  );
}

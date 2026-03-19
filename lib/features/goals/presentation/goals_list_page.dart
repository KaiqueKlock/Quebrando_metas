import 'package:flutter/widgets.dart';
import 'package:quebrando_metas/features/dashboard/presentation/dashboard_page.dart';

class GoalsListPage extends StatelessWidget {
  const GoalsListPage({super.key});

  static const Key createGoalFabKey = DashboardPage.createGoalFabKey;
  static const Key goalsListScrollKey = DashboardPage.goalsListScrollKey;

  @override
  Widget build(BuildContext context) {
    return const DashboardPage();
  }
}

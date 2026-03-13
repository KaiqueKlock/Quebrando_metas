import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quebrando_metas/app/router.dart';

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index == currentIndex) return;
        if (index == 0) {
          context.go(AppRoutes.dashboard);
          return;
        }
        context.go(AppRoutes.goals);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.checklist_outlined),
          selectedIcon: Icon(Icons.checklist),
          label: 'Suas Metas',
        ),
      ],
    );
  }
}

class NearNavBarFabLocation extends FloatingActionButtonLocation {
  const NearNavBarFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX =
        (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2;
    final double navTop = scaffoldGeometry.contentBottom;
    final double fabY =
        navTop - scaffoldGeometry.floatingActionButtonSize.height - 8;
    return Offset(fabX, fabY);
  }
}

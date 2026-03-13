import 'package:flutter/material.dart';
import 'package:quebrando_metas/app/router.dart';
import 'package:quebrando_metas/app/theme/app_theme.dart';
import 'package:quebrando_metas/app/theme/app_theme_settings.dart';
import 'package:quebrando_metas/core/constants/app_constants.dart';

class QuebrandoMetasApp extends StatelessWidget {
  const QuebrandoMetasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeSettings settings = AppThemeSettings.instance;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp.router(
          title: AppConstants.appName,
          theme: AppTheme.light(settings.seedColor),
          darkTheme: AppTheme.dark(settings.seedColor),
          themeMode: settings.themeMode,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:quebrando_metas/app/router.dart';
import 'package:quebrando_metas/app/theme/app_theme.dart';
import 'package:quebrando_metas/core/constants/app_constants.dart';

class QuebrandoMetasApp extends StatelessWidget {
  const QuebrandoMetasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light(),
      routerConfig: AppRouter.router,
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quebrando_metas/app/app.dart';
import 'package:quebrando_metas/app/onboarding_status.dart';
import 'package:quebrando_metas/app/theme/app_theme_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await OnboardingStatus.instance.init();
  await AppThemeSettings.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.overrides = const <Override>[]});

  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: const QuebrandoMetasApp(),
    );
  }
}
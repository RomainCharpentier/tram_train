import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:workmanager/workmanager.dart';

import 'package:train_qil/env_config.dart';
import 'package:train_qil/infrastructure/background/trip_status_worker.dart';
import 'package:train_qil/infrastructure/dependency_injection.dart';
import 'package:train_qil/view/pages/root_navigation_page.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await EnvConfig.load();
    final bool isMobilePlatform = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (isMobilePlatform) {
      await Workmanager().initialize(
        tripStatusCallbackDispatcher,
        isInDebugMode: kDebugMode,
      );
    }
    await DependencyInjection.initialize();
    await initializeDateFormatting('fr_FR');
    runApp(const MyApp());
  } on Object catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Erreur: $e'),
        ),
      ),
    ));
  }
}

class EnvInheritedWidget extends InheritedWidget {
  final String apiKey;

  const EnvInheritedWidget({
    super.key,
    required super.child,
    required this.apiKey,
  });

  static EnvInheritedWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EnvInheritedWidget>();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = DependencyInjection.instance.themeService;

    return AnimatedBuilder(
      animation: themeService,
      builder: (context, child) {
        return MaterialApp(
          title: "Train'Qil",
          theme: themeService.lightTheme,
          darkTheme: themeService.darkTheme,
          themeMode: themeService.themeMode,
          home: const RootNavigationPage(),
        );
      },
    );
  }
}

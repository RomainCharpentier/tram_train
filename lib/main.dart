import 'package:flutter/material.dart';
import 'package:train_qil/env_config.dart';
import 'package:train_qil/infrastructure/dependency_injection.dart';
import 'package:train_qil/view/pages/home_page.dart';

void main() async {
  try {
    await EnvConfig.load();
    await DependencyInjection.initialize();
    runApp(const MyApp());
  } catch (e) {
    print('Erreur lors de l\'initialisation: $e');
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
          title: 'Train\'Qil',
          theme: themeService.lightTheme,
          darkTheme: themeService.darkTheme,
          themeMode: themeService.themeMode,
          home: const HomePage(),
        );
      },
    );
  }
}

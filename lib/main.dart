import 'package:flutter/material.dart';
import 'package:tram_train/env_config.dart';
import 'package:tram_train/dependency_injection.dart';
import 'package:tram_train/view/pages/home_page.dart';

void main() async {
  await EnvConfig.load();
  await DependencyInjection.initialize();

  runApp(const MyApp());
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
    return MaterialApp(
      title: 'Tram Train',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tram_train/env_config.dart';
import 'home_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await EnvConfig.load();

  runApp(const MyApp());
}

class EnvInheritedWidget extends InheritedWidget {
  final String apiKey;

  const EnvInheritedWidget({
    super.key,
    required Widget child,
    required this.apiKey,
  }) : super(child: child);

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
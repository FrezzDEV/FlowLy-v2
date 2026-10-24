import 'package:flutter/material.dart';

import 'circle_reveal_demo_page.dart';

/// Запуск примера отдельно:
/// flutter run -t lib/examples/main.dart
void main() {
  runApp(const CircleRevealExampleApp());
}

class CircleRevealExampleApp extends StatelessWidget {
  const CircleRevealExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Circle Reveal Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF08090B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB6F36B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const CircleRevealDemoPage(),
    );
  }
}

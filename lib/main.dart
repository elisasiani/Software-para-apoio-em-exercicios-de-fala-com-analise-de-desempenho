import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/user_progress.dart';
import 'screens/welcome_screen2.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProgress(),
      child: const FonoApp(),
    ),
  );
}

class FonoApp extends StatelessWidget {
  const FonoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFBC4ED8),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFFBC4ED8),
          secondary: const Color(0xFF7F00B2),
          surface: const Color(0xFFFFF0FF),
        );

    return MaterialApp(
      title: 'Liri',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFFFF0FF),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xFF7F00B2),
          displayColor: const Color(0xFF7F00B2),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

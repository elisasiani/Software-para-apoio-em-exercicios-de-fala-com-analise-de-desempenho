import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/user_progress.dart';
import 'screens/welcome_screen2.dart';
import 'theme/app_theme.dart';

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
    return MaterialApp(
      title: 'Liri',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const WelcomeScreen(),
    );
  }
}

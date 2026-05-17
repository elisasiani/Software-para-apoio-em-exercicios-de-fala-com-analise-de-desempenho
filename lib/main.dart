import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user_progress.dart';
import 'screens/welcome_screen2.dart';
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart'; //Importa o Firebase
import 'firebase_options.dart'; // 2. Importa as chaves que o CLI gerou

void main() async {

  WidgetsFlutterBinding.ensureInitialized();  // Essa linha garante que a comunicação com o firebase esteja pronta antes de iniciar o app

  await Firebase.initializeApp( // Escolhe a chave certa do CLI para rodar ou no Android ou no IOS
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

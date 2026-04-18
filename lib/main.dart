import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // NOVO: Importação do Firebase
import 'firebase_options.dart'; // NOVO: Importação das configurações que você gerou
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'models/user_progress.dart';
import 'package:provider/provider.dart';

void main() async { // ALTERADO: Adicionado 'async'
  // 1. Garante que os plugins do Flutter estejam prontos
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa o Firebase antes de rodar o App
  await Firebase.initializeApp(
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B2FBE),
          primary: const Color(0xFF7B2FBE),
          secondary: const Color(0xFFCE93D8),
          surface: const Color(0xFFF8F0FF),
        ),
        fontFamily: 'Nunito',
      ),
      home: const LoginScreen(),
    );
  }
}
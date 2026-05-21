import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'models/user_progress.dart';
import 'screens/welcome_screen2.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  // Inicializa o Firebase ANTES do runApp
  WidgetsFlutterBinding.ensureInitialized();
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
      theme: AppTheme.lightTheme,
      // O AuthGate decide: se já logado vai pra Home, senão Welcome
      home: const AuthGate(),
    );
  }
}

/// Decide a tela inicial com base no estado do Firebase Auth.
/// - Se há usuário logado: vai direto para HomeScreen
/// - Senão: mostra a Welcome screen (que leva ao login)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFFF0FF),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Logado — vai para Home com o UID do paciente
          return HomeScreen(pacienteId: snapshot.data!.uid);
        }

        // Não logado — fluxo normal de boas-vindas
        return const WelcomeScreen();
      },
    );
  }
}

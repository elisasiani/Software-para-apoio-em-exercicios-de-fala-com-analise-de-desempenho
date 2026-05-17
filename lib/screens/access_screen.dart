import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart'; 
import '../models/user_progress.dart'; 
import 'home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key});

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'LeagueSpartan'),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.secondary,
      ),
    );
  }

  Future<void> _handleLogin() async {
    final login = _loginController.text.trim();
    final password = _passwordController.text;

    if (login.isEmpty || password.isEmpty) {
      _showMessage('Por favor, informe o login e a senha.');
      return;
    }

    try {
      print("=== INICIANDO TENTATIVA DE LOGIN POR CAMPO ===");

      // ALTERAÇÃO AQUI: Em vez de buscar pelo ID do documento, 
      // filtramos a coleção procurando onde o CAMPO 'login' é igual ao digitado
      var querySnapshot = await FirebaseFirestore.instance
          .collection('pacientes')
          .where('Login Paciente', isEqualTo: login)
          .get();

      // Se a lista de documentos encontrados não estiver vazia
      if (querySnapshot.docs.isNotEmpty) {
        // Pegamos o primeiro paciente encontrado com esse login
        var doc = querySnapshot.docs.first;
        var dados = doc.data();

        // Verifica a senha
        if (dados['Senha Paciente'] == password) {
          
          // Sucesso! Atualiza o Provider usando o NOME REAL
          final userProgress = Provider.of<UserProgress>(context, listen: false);
          userProgress.updateUserName(dados['Nome'] ?? login);

          // Navega para a HomeScreen
          if (mounted) { 
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              ),
            );
          }
        } else {
          _showMessage('Senha incorreta. Tente novamente.');
        }
      } else {
        // Se a busca pelo campo 'login' não retornou nenhum documento
        _showMessage('Paciente não encontrado. Verifique o login.');
      }
    } catch (e) {
      _showMessage('Erro de conexão. Tente novamente mais tarde.');
      print("Erro detalhado do Firebase: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFCE89), // Cor de fundo especificada para AccessScreen
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 32),
            child: SizedBox(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ilustração do Topo
                  Center(
                    child: SizedBox(
                      height: 200,
                      child: SvgPicture.asset(
                        'assets/images/Prancheta3.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  
                  // Título
                  Text(
                    'Que Bom Que Voltou!',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 24,
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campos de Entrada
                  _AccessTextField(
                    controller: _loginController,
                    hintText: 'Login',
                  ),
                  const SizedBox(height: 15),
                  _AccessTextField(
                    controller: _passwordController,
                    hintText: 'Senha',
                    obscureText: true,
                  ),
                  const SizedBox(height: 15),

                  // Texto Instrutivo
                  Text(
                    'Informe o login e senha que sua fono te passou!',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 16, // Mantido de correção anterior
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Botão Principal
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Acessar',
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessTextField extends StatelessWidget {
  const _AccessTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        fontFamily: 'LeagueSpartan',
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: 'LeagueSpartan',
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

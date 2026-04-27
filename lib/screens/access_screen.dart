import 'package:flutter/material.dart';

import 'perfil_screen.dart';
import 'register_screen.dart';

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key});

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF7F00B2),
      ),
    );
  }

  String _resolveProfileType(String email) {
    final normalized = email.toLowerCase();
    if (normalized.contains('fono') ||
        normalized.contains('terapeuta') ||
        normalized.contains('prof')) {
      return 'fono';
    }
    return 'crianca';
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Preencha email e senha para continuar.');
      return;
    }

    if (!email.contains('@')) {
      _showMessage('Digite um email válido.');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PerfilScreen(
          nomeUsuario: email,
          tipoPerfil: _resolveProfileType(email),
        ),
      ),
    );
  }

  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      backgroundColor: const Color(0xFFC77ADB),
      titleColor: const Color(0xFFC75000),
      actionColor: const Color(0xFFC75000),
      title: 'Que bom que voltou!',
      imageAsset: 'assets/images/access_illustration.png',
      primaryActionLabel: 'Acessar',
      onPrimaryAction: _submit,
      fields: [
        AuthFieldData(
          controller: _emailController,
          hintText: 'Email',
          textColor: const Color(0xFF7F00B2),
          keyboardType: TextInputType.emailAddress,
        ),
        AuthFieldData(
          controller: _passwordController,
          hintText: 'Senha',
          textColor: const Color(0xFF7F00B2),
          obscureText: true,
        ),
      ],
      bottomPrompt: const AuthPromptData(
        leading: 'Não possui uma conta?',
        action: 'Cadastre-se',
        leadingColor: Color(0xFF7F00B2),
      ),
      onPromptTap: _openRegister,
      footer: Center(
        child: GestureDetector(
          onTap: () => _showMessage('Recuperação de senha em breve.'),
          child: const Text(
            'Esqueci minha senha',
            style: TextStyle(
              color: Color(0xFF7F00B2),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

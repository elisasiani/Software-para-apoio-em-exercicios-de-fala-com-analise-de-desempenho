import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_progress.dart';
import 'home_screen.dart';

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key});

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _carregando = false;

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

  /// Converte um login amigável ("joao.123") no e-mail interno
  /// ("joao.123@liri.app") que o Firebase Auth usa.
  String _loginParaEmail(String login) {
    final limpo =
        login.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (limpo.contains('@')) return limpo;
    return '$limpo@liri.app';
  }

  String _traduzirErroAuth(String code) {
    switch (code) {
      case 'invalid-email':          return 'Login inválido.';
      case 'user-not-found':         return 'Usuário não encontrado.';
      case 'wrong-password':         return 'Senha incorreta.';
      case 'invalid-credential':     return 'Login ou senha incorretos.';
      case 'too-many-requests':      return 'Muitas tentativas. Tente mais tarde.';
      case 'user-disabled':          return 'Conta desativada.';
      case 'network-request-failed': return 'Sem conexão com a internet.';
      default:                       return 'Erro ao entrar. Tente novamente.';
    }
  }

  Future<void> _handleLogin() async {
    final login = _loginController.text.trim();
    final password = _passwordController.text;

    if (login.isEmpty || password.isEmpty) {
      _showMessage('Por favor, informe o login e a senha.');
      return;
    }

    setState(() => _carregando = true);
    try {
      final email = _loginParaEmail(login);
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Confirma que é mesmo um paciente
      final doc = await FirebaseFirestore.instance
          .collection('pacientes')
          .doc(cred.user!.uid)
          .get();

      if (!doc.exists || (doc.data()?['tipo'] != 'paciente')) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        _showMessage('Este login não é de um paciente.');
        return;
      }

      // Atualiza o nome no UserProgress local para uso imediato na Home
      if (mounted) {
        final nome = (doc.data()?['nome'] as String?) ?? login;
        Provider.of<UserProgress>(context, listen: false)
            .updateUserName(nome.split(' ').first);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(pacienteId: cred.user!.uid),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(_traduzirErroAuth(e.code));
    } catch (_) {
      _showMessage('Erro ao entrar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFCE89),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 32),
            child: SizedBox(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  Text(
                    'Informe o login e senha que sua fono te passou!',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 50),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _carregando ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        disabledBackgroundColor:
                            theme.colorScheme.secondary.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _carregando ? 'Entrando...' : 'Acessar',
                        style: const TextStyle(
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
      style: const TextStyle(fontFamily: 'LeagueSpartan', fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: 'LeagueSpartan',
          color: theme.colorScheme.onSurface.withOpacity(0.4),
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

import 'package:flutter/material.dart';

import 'access_screen.dart';
import 'perfil_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
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

  void _submit() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Preencha nome, email e senha para continuar.');
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
          nomeUsuario: name,
          tipoPerfil: 'crianca',
        ),
      ),
    );
  }

  void _openAccess() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccessScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      backgroundColor: const Color(0xFFFFCE89),
      titleColor: const Color(0xFF7F00B2),
      actionColor: const Color(0xFF7F00B2),
      title: 'Pronto para praticar?',
      imageAsset: 'assets/images/register_illustration.png',
      primaryActionLabel: 'Estou pronto!',
      onPrimaryAction: _submit,
      fields: [
        AuthFieldData(
          controller: _nameController,
          hintText: 'Seu nome',
          textColor: const Color(0xFFCA8629),
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
        ),
        AuthFieldData(
          controller: _emailController,
          hintText: 'Email',
          textColor: const Color(0xFFCA8629),
          keyboardType: TextInputType.emailAddress,
        ),
        AuthFieldData(
          controller: _passwordController,
          hintText: 'Senha',
          textColor: const Color(0xFFCA8629),
          obscureText: true,
        ),
      ],
      bottomPrompt: const AuthPromptData(
        leading: 'Já possui uma conta?',
        action: 'Acesse',
        leadingColor: Color(0xFFCA8629),
      ),
      onPromptTap: _openAccess,
      footer: null,
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.backgroundColor,
    required this.titleColor,
    required this.actionColor,
    required this.title,
    required this.imageAsset,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.fields,
    required this.bottomPrompt,
    required this.onPromptTap,
    required this.footer,
  });

  final Color backgroundColor;
  final Color titleColor;
  final Color actionColor;
  final String title;
  final String imageAsset;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final List<AuthFieldData> fields;
  final AuthPromptData bottomPrompt;
  final VoidCallback onPromptTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(30, 32, 30, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 255,
                    child: Center(
                      child: Image.asset(
                        imageAsset,
                        width: 318,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final field in fields) ...[
                    AuthTextField(field: field),
                    const SizedBox(height: 15),
                  ],
                  const SizedBox(height: 10),
                  if (footer != null) ...[
                    footer!,
                    const SizedBox(height: 18),
                  ],
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          bottomPrompt.leading,
                          style: TextStyle(
                            color: bottomPrompt.leadingColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: onPromptTap,
                          child: Text(
                            bottomPrompt.action,
                            style: TextStyle(
                              color: actionColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 57,
                    child: ElevatedButton(
                      onPressed: onPrimaryAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7F00B2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        primaryActionLabel,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
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

class AuthFieldData {
  const AuthFieldData({
    required this.controller,
    required this.hintText,
    required this.textColor,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hintText;
  final Color textColor;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({super.key, required this.field});

  final AuthFieldData field;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: field.controller,
      obscureText: field.obscureText,
      keyboardType: field.keyboardType,
      textCapitalization: field.textCapitalization,
      style: TextStyle(
        color: field.textColor,
        fontSize: 20,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: field.hintText,
        hintStyle: TextStyle(
          color: field.textColor,
          fontSize: 20,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0x80ECF1FF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: field.textColor.withValues(alpha: 0.55),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class AuthPromptData {
  const AuthPromptData({
    required this.leading,
    required this.action,
    required this.leadingColor,
  });

  final String leading;
  final String action;
  final Color leadingColor;
}

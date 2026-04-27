import 'package:flutter/material.dart';
import 'perfil_screen.dart'; // Nova tela de seleção de perfil

// ==============================================================
// LOGIN SCREEN — Liri
// Tela inicial com login para Criança e Fonoaudiólogo.
// Após login bem-sucedido, vai para PerfilScreen onde o usuário
// pode ver e trocar entre os perfis disponíveis.
// ==============================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 0 = Criança, 1 = Fonoaudiólogo
  int _abaSelecionada = 0;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaFonoController = TextEditingController();

  bool _mostrarSenha = false;
  bool _mostrarSenhaFono = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _senhaController.dispose();
    _emailController.dispose();
    _senhaFonoController.dispose();
    super.dispose();
  }

  void _loginCrianca() {
    if (_nomeController.text.trim().isEmpty) {
      _mostrarErro('Por favor, escreva seu nome! 😊');
      return;
    }
    // Vai para a tela de perfis passando nome e tipo
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PerfilScreen(
          nomeUsuario: _nomeController.text.trim(),
          tipoPerfil: 'crianca',
        ),
      ),
    );
  }

  void _loginFono() {
    if (_emailController.text.trim().isEmpty ||
        _senhaFonoController.text.isEmpty) {
      _mostrarErro('Preencha todos os campos! 📋');
      return;
    }
    if (!_emailController.text.contains('@')) {
      _mostrarErro('E-mail inválido!');
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PerfilScreen(
          nomeUsuario: _emailController.text.trim(),
          tipoPerfil: 'fono',
        ),
      ),
    );
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF7B2FBE),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 36),

                // ── Logo: emoji da girafa + nome Liri ──────────
                _buildLogo(),

                const SizedBox(height: 32),

                // ── Seletor de perfil ────────────────────────
                _buildSeletorPerfil(),

                const SizedBox(height: 28),

                // ── Formulário (troca com animação) ───────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _abaSelecionada == 0
                      ? _buildFormCrianca()
                      : _buildFormFono(),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo do Liri ──────────────────────────────────────────────
  Widget _buildLogo() {
    return Column(
      children: [
        // Emoji da girafa como ícone do app — grande e infantil
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B2FBE).withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            // Emoji nativo da girafa — sem assets externos
            child: Text('🦒', style: TextStyle(fontSize: 62)),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Liri',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A148C),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Vamos aprender juntos! 🌟',
          style: TextStyle(fontSize: 15, color: Color(0xFF9C27B0)),
        ),
      ],
    );
  }

  // ── Seletor de perfil (dois botões) ──────────────────────────
  Widget _buildSeletorPerfil() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _botaoPerfil(0, '🧒', 'Sou Criança'),
          _botaoPerfil(1, '👩‍⚕️', 'Fonoaudiólogo'),
        ],
      ),
    );
  }

  Widget _botaoPerfil(int indice, String emoji, String rotulo) {
    final ativo = _abaSelecionada == indice;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _abaSelecionada = indice),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: ativo ? const Color(0xFF7B2FBE) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(emoji, style: TextStyle(fontSize: ativo ? 28 : 24)),
              const SizedBox(height: 4),
              Text(
                rotulo,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ativo ? Colors.white : const Color(0xFF7B2FBE),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Formulário da Criança ─────────────────────────────────────
  Widget _buildFormCrianca() {
    return Column(
      key: const ValueKey('form_crianca'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardFormulario(
          children: [
            _labelCampo('Qual é o seu nome?'),
            const SizedBox(height: 10),
            _campo(
              controller: _nomeController,
              hint: 'Ex: Ana Clara',
              icone: Icons.person_outline_rounded,
              capitalizacao: TextCapitalization.words,
            ),
            const SizedBox(height: 18),
            _labelCampo('Sua senha:'),
            const SizedBox(height: 10),
            _campoSenha(
              controller: _senhaController,
              mostrar: _mostrarSenha,
              onToggle: () => setState(() => _mostrarSenha = !_mostrarSenha),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _botaoEntrar('Vamos lá! 🚀', _loginCrianca),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => _mostrarErro('Cadastro em breve! 😊'),
            child: const Text(
              'Não tenho conta — Criar conta',
              style: TextStyle(
                color: Color(0xFF7B2FBE),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Formulário do Fonoaudiólogo ───────────────────────────────
  Widget _buildFormFono() {
    return Column(
      key: const ValueKey('form_fono'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardFormulario(
          children: [
            const Text(
              'Acesso Profissional',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A148C),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Área restrita para fonoaudiólogos',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 18),
            _campo(
              controller: _emailController,
              hint: 'seu@email.com',
              icone: Icons.email_outlined,
              tipo: TextInputType.emailAddress,
              rotulo: 'E-mail profissional',
            ),
            const SizedBox(height: 14),
            _campoSenha(
              controller: _senhaFonoController,
              mostrar: _mostrarSenhaFono,
              onToggle: () =>
                  setState(() => _mostrarSenhaFono = !_mostrarSenhaFono),
              rotulo: 'Senha',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Esqueci minha senha',
                  style: TextStyle(color: Color(0xFF7B2FBE), fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _botaoEntrar('Entrar', _loginFono),
      ],
    );
  }

  // ── Helpers de UI reutilizáveis ───────────────────────────────

  Widget _cardFormulario({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2FBE).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _labelCampo(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4A148C),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String hint,
    required IconData icone,
    TextInputType tipo = TextInputType.text,
    TextCapitalization capitalizacao = TextCapitalization.none,
    String? rotulo,
  }) {
    return TextField(
      controller: controller,
      keyboardType: tipo,
      textCapitalization: capitalizacao,
      style: const TextStyle(fontSize: 16, color: Color(0xFF4A148C)),
      decoration: InputDecoration(
        labelText: rotulo,
        labelStyle: const TextStyle(color: Color(0xFF9C27B0)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icone, color: const Color(0xFF7B2FBE)),
        filled: true,
        fillColor: const Color(0xFFF8F0FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF7B2FBE), width: 2),
        ),
      ),
    );
  }

  Widget _campoSenha({
    required TextEditingController controller,
    required bool mostrar,
    required VoidCallback onToggle,
    String? rotulo,
  }) {
    return TextField(
      controller: controller,
      obscureText: !mostrar,
      style: const TextStyle(fontSize: 16, color: Color(0xFF4A148C)),
      decoration: InputDecoration(
        labelText: rotulo,
        labelStyle: const TextStyle(color: Color(0xFF9C27B0)),
        hintText: rotulo == null ? 'Digite sua senha' : null,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon:
            const Icon(Icons.lock_outline_rounded, color: Color(0xFF7B2FBE)),
        suffixIcon: IconButton(
          icon: Icon(
            mostrar ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: const Color(0xFF9C27B0),
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F0FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF7B2FBE), width: 2),
        ),
      ),
    );
  }

  Widget _botaoEntrar(String texto, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7B2FBE),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 4,
      ),
      child: Text(
        texto,
        style:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

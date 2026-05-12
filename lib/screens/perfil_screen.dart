import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercicio.dart';
import '../models/user_progress.dart';
import 'home_screen.dart';
import 'welcome_screen2.dart';

// ==============================================================
// PERFIL SCREEN — tela central após o login
//
// Essa tela é o "hub" do Liri. Ela aparece logo após o login e
// mostra o perfil ativo do usuário (criança ou fonoaudiólogo).
//
// Para a CRIANÇA: mostra resumo das trilhas e relatório pessoal.
// Para o FONO:   mostra a lista de pacientes e relatórios deles.
//
// É um StatefulWidget porque a aba inferior pode trocar.
// ==============================================================
class PerfilScreen extends StatefulWidget {
  final String nomeUsuario;
  final String tipoPerfil; // 'crianca' ou 'fono'

  const PerfilScreen({
    super.key,
    required this.nomeUsuario,
    required this.tipoPerfil,
  });

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  // Controla qual aba do BottomNavigationBar está ativa
  int _abaSelecionada = 0;

  @override
  Widget build(BuildContext context) {
    // As abas mudam dependendo do tipo de perfil
    final bool ehFono = widget.tipoPerfil == 'fono';
    final bool mostrarHomeCrianca = !ehFono && _abaSelecionada == 0;

    return Scaffold(
      backgroundColor: mostrarHomeCrianca
          ? const Color(0xFFD77CF2)
          : const Color(0xFFF8F0FF),

      // ── AppBar com identidade do Liri ─────────────────────────
      appBar: mostrarHomeCrianca
          ? null
          : AppBar(
        backgroundColor: const Color(0xFF7B2FBE),
        automaticallyImplyLeading: false, // Remove o botão de voltar
        title: Row(
          children: [
            // Emoji da girafa no topo
            const Text('🦒', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            const Text(
              'Liri',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          // Botão de trocar perfil — volta para o login
          TextButton.icon(
            onPressed: _sair,
            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white70, size: 20),
            label: const Text(
              'Trocar',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          // Botão de sair
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Sair',
            onPressed: _sair,
          ),
        ],
      ),

      // ── Corpo: muda conforme a aba selecionada ─────────────────
      body: ehFono
          ? _buildConteudoFono()
          : _buildConteudoCrianca(),

      // ── Barra de navegação inferior ───────────────────────────
      bottomNavigationBar: mostrarHomeCrianca
          ? null
          : BottomNavigationBar(
        currentIndex: _abaSelecionada,
        onTap: (index) => setState(() => _abaSelecionada = index),
        selectedItemColor: const Color(0xFF7B2FBE),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: ehFono
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outlined),
                  activeIcon: Icon(Icons.people_rounded),
                  label: 'Pacientes',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined),
                  activeIcon: Icon(Icons.bar_chart_rounded),
                  label: 'Relatórios',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Meu Perfil',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined),
                  activeIcon: Icon(Icons.map_rounded),
                  label: 'Trilhas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined),
                  activeIcon: Icon(Icons.bar_chart_rounded),
                  label: 'Relatório',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Perfil',
                ),
              ],
      ),
    );
  }

  void _sair() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  CONTEÚDO DA CRIANÇA  (3 abas: Trilhas / Relatório / Perfil)
  // ════════════════════════════════════════════════════════════
  Widget _buildConteudoCrianca() {
    // Consumer: escuta mudanças no UserProgress e reconstrói a UI
    return Consumer<UserProgress>(
      builder: (context, progresso, child) {
        switch (_abaSelecionada) {
          case 0:
            return HomeScreen(
              nomeUsuario: widget.nomeUsuario,
              onTabSelected: (index) => setState(() => _abaSelecionada = index),
            );
          case 1:
            return _AbaRelatorioCrianca(progresso: progresso);
          case 2:
            return _AbaPerfilCrianca(nomeUsuario: widget.nomeUsuario);
          default:
            return const SizedBox();
        }
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  //  CONTEÚDO DO FONO  (3 abas: Pacientes / Relatórios / Perfil)
  // ════════════════════════════════════════════════════════════
  Widget _buildConteudoFono() {
    switch (_abaSelecionada) {
      case 0:
        return _AbaPacientesFono(emailFono: widget.nomeUsuario);
      case 1:
        return const _AbaRelatoriosFono();
      case 2:
        return _AbaPerfilFono(emailFono: widget.nomeUsuario);
      default:
        return const SizedBox();
    }
  }
}

// ════════════════════════════════════════════════════════════
//  ABA TRILHAS — CRIANÇA
// ════════════════════════════════════════════════════════════
// ignore: unused_element
class _AbaTrilhasCrianca extends StatelessWidget {
  final String nomeUsuario;
  final UserProgress progresso;

  const _AbaTrilhasCrianca({
    required this.nomeUsuario,
    required this.progresso,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho de boas-vindas ────────────────────────
          Text(
            'Olá, $nomeUsuario! 👋',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'O que vamos treinar hoje?',
            style: TextStyle(fontSize: 15, color: Color(0xFF9C27B0)),
          ),
          const SizedBox(height: 20),

          // ── Card de progresso rápido ─────────────────────────
          _cardProgressoRapido(progresso),
          const SizedBox(height: 24),

          // ── Lista de trilhas ─────────────────────────────────
          const Text(
            'Suas Trilhas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C),
            ),
          ),
          const SizedBox(height: 14),

          // Gera um card para cada trilha nos dados estáticos
          ...DadosApp.trilhas.map(
            (trilha) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _CartaoTrilha(trilha: trilha, progresso: progresso),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardProgressoRapido(UserProgress progresso) {
    final totalFeitos = DadosApp.trilhas
        .map((t) => progresso.getProgressoTrilha(t.id))
        .fold(0, (soma, v) => soma + v);
    final total = DadosApp.trilhas.length * 5;
    final pct = totalFeitos / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B2FBE), Color(0xFFAB47BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2FBE).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícone de troféu
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🏆', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalFeitos de $total exercícios',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: Colors.white30,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.yellow),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(pct * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.yellow,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Card de cada trilha (reutilizável)
class _CartaoTrilha extends StatelessWidget {
  final Trilha trilha;
  final UserProgress progresso;

  const _CartaoTrilha({required this.trilha, required this.progresso});

  @override
  Widget build(BuildContext context) {
    final prog = progresso.getProgressoTrilha(trilha.id);
    final concluida = prog >= 5;

    return GestureDetector(
      onTap: () {
        // Navega para a HomeScreen existente que já tem as trilhas
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(nomeUsuario: ''),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: concluida ? Colors.green : const Color(0xFFCE93D8),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji da trilha
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(trilha.emoji,
                    style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trilha.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    trilha.subtitulo,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  // Barra de progresso
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: prog / 5,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFE1BEE7),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              concluida
                                  ? Colors.green
                                  : const Color(0xFF7B2FBE),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$prog/5',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: concluida
                              ? Colors.green
                              : const Color(0xFF7B2FBE),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              concluida
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: concluida ? Colors.green : const Color(0xFF9C27B0),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ABA RELATÓRIO — CRIANÇA
// ════════════════════════════════════════════════════════════
class _AbaRelatorioCrianca extends StatelessWidget {
  final UserProgress progresso;

  const _AbaRelatorioCrianca({required this.progresso});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meu Relatório 📊',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Veja como você está indo!',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),

          // ── Cards de métricas ───────────────────────────────
          Row(
            children: [
              _CardMetrica(
                emoji: '🔥',
                valor: '${progresso.streakDays}',
                rotulo: 'dias\nsequência',
                cor: Colors.orange.shade100,
              ),
              const SizedBox(width: 12),
              _CardMetrica(
                emoji: '⭐',
                valor: '${progresso.totalStars}',
                rotulo: 'estrelas\nganhas',
                cor: Colors.yellow.shade100,
              ),
              const SizedBox(width: 12),
              _CardMetrica(
                emoji: '✅',
                valor: '${DadosApp.trilhas.map((t) => progresso.getProgressoTrilha(t.id)).fold(0, (s, v) => s + v)}',
                rotulo: 'exerc.\nfeitos',
                cor: Colors.green.shade100,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Progresso por trilha ────────────────────────────
          const Text(
            'Progresso por Trilha',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C),
            ),
          ),
          const SizedBox(height: 14),

          ...DadosApp.trilhas.map((trilha) {
            final prog = progresso.getProgressoTrilha(trilha.id);
            final pct = prog / 5;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(trilha.emoji,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              trilha.titulo,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A148C),
                              ),
                            ),
                          ],
                        ),
                        // Badge de desempenho
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: pct >= 1.0
                                ? Colors.green.withValues(alpha: 0.15)
                                : const Color(0xFFEDE7F6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            pct >= 1.0
                                ? '✅ Concluído'
                                : pct > 0
                                    ? '🔄 Em andamento'
                                    : '🔒 Não iniciado',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: pct >= 1.0
                                  ? Colors.green.shade700
                                  : const Color(0xFF7B2FBE),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE1BEE7),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          pct >= 1.0 ? Colors.green : const Color(0xFF7B2FBE),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$prog de 5 exercícios concluídos',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // ── Mensagem motivacional ───────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFCE93D8), width: 1.5),
            ),
            child: const Column(
              children: [
                Text('🦒', style: TextStyle(fontSize: 36)),
                SizedBox(height: 8),
                Text(
                  'Continue assim! Você está indo muito bem!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A148C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Card de métrica (estrelas, streak, etc.)
class _CardMetrica extends StatelessWidget {
  final String emoji;
  final String valor;
  final String rotulo;
  final Color cor;

  const _CardMetrica({
    required this.emoji,
    required this.valor,
    required this.rotulo,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A148C),
              ),
            ),
            Text(
              rotulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ABA PERFIL — CRIANÇA
// ════════════════════════════════════════════════════════════
class _AbaPerfilCrianca extends StatelessWidget {
  final String nomeUsuario;
  const _AbaPerfilCrianca({required this.nomeUsuario});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Avatar com emoji da girafa
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7F6),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF7B2FBE), width: 3),
            ),
            child: const Center(
              child: Text('🦒', style: TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nomeUsuario,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🧒 Usuário',
              style: TextStyle(
                color: Color(0xFF7B2FBE),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _itemPerfil(Icons.edit_outlined, 'Editar nome'),
          _itemPerfil(Icons.notifications_outlined, 'Notificações'),
          _itemPerfil(Icons.help_outline_rounded, 'Ajuda'),
          _itemPerfil(Icons.info_outline_rounded, 'Sobre o Liri'),
        ],
      ),
    );
  }

  Widget _itemPerfil(IconData icone, String titulo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icone, color: const Color(0xFF7B2FBE)),
        title:
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ABA PACIENTES — FONOAUDIÓLOGO
// ════════════════════════════════════════════════════════════
class _AbaPacientesFono extends StatelessWidget {
  final String emailFono;

  const _AbaPacientesFono({required this.emailFono});

  // Dados mockados dos pacientes — no futuro viria do Firebase
  static const List<Map<String, dynamic>> _pacientes = [
    {
      'nome': 'Ana Clara',
      'exerciciosFeitos': 7,
      'totalExercicios': 10,
      'ultimaAtividade': 'Hoje',
      'streakDias': 5,
      'status': 'ativo',
    },
    {
      'nome': 'Pedro Henrique',
      'exerciciosFeitos': 3,
      'totalExercicios': 10,
      'ultimaAtividade': 'Ontem',
      'streakDias': 2,
      'status': 'ativo',
    },
    {
      'nome': 'Mariana Silva',
      'exerciciosFeitos': 10,
      'totalExercicios': 10,
      'ultimaAtividade': 'Hoje',
      'streakDias': 7,
      'status': 'concluido',
    },
    {
      'nome': 'Lucas Oliveira',
      'exerciciosFeitos': 1,
      'totalExercicios': 10,
      'ultimaAtividade': 'Há 3 dias',
      'streakDias': 0,
      'status': 'inativo',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2FBE), Color(0xFFAB47BC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '👩‍⚕️ Bem-vinda(o)!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  emailFono,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                // Resumo rápido
                Row(
                  children: [
                    _chipResumo('${_pacientes.length}', 'pacientes'),
                    const SizedBox(width: 10),
                    _chipResumo(
                      '${_pacientes.where((p) => p['status'] == 'ativo').length}',
                      'ativos hoje',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'Seus Pacientes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C),
            ),
          ),
          const SizedBox(height: 14),

          // Lista de pacientes
          ..._pacientes.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CartaoPaciente(paciente: p),
              )),

          const SizedBox(height: 8),

          // Botão de adicionar paciente
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add_outlined,
                  color: Color(0xFF7B2FBE)),
              label: const Text(
                'Adicionar Paciente',
                style: TextStyle(
                  color: Color(0xFF7B2FBE),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF7B2FBE), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipResumo(String valor, String rotulo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$valor $rotulo',
        style: const TextStyle(
            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// Card de cada paciente
class _CartaoPaciente extends StatelessWidget {
  final Map<String, dynamic> paciente;
  const _CartaoPaciente({required this.paciente});

  Color _corStatus() {
    switch (paciente['status']) {
      case 'concluido':
        return Colors.green;
      case 'inativo':
        return Colors.red.shade300;
      default:
        return const Color(0xFF7B2FBE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = paciente['exerciciosFeitos'] / paciente['totalExercicios'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1BEE7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFEDE7F6),
            child: Text(
              paciente['nome'][0],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B2FBE),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      paciente['nome'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A148C),
                      ),
                    ),
                    // Streak do paciente
                    Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 13)),
                        Text(
                          '${paciente['streakDias']}d',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE1BEE7),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_corStatus()),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${paciente['exerciciosFeitos']}/${paciente['totalExercicios']} exercícios',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black54),
                    ),
                    Text(
                      paciente['ultimaAtividade'],
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ABA RELATÓRIOS — FONOAUDIÓLOGO
// ════════════════════════════════════════════════════════════
class _AbaRelatoriosFono extends StatelessWidget {
  const _AbaRelatoriosFono();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Relatórios 📊',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Visão geral de todos os pacientes',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),

          // ── Cards de resumo geral ────────────────────────────
          Row(
            children: [
              _CardRelatorio(
                emoji: '👥',
                valor: '4',
                rotulo: 'Pacientes',
                cor: const Color(0xFFEDE7F6),
              ),
              const SizedBox(width: 12),
              _CardRelatorio(
                emoji: '✅',
                valor: '21',
                rotulo: 'Exercícios\nfeitos',
                cor: Colors.green.shade50,
              ),
              const SizedBox(width: 12),
              _CardRelatorio(
                emoji: '📈',
                valor: '53%',
                rotulo: 'Média\ngeral',
                cor: Colors.blue.shade50,
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Desempenho Individual',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C),
            ),
          ),
          const SizedBox(height: 14),

          // Relatório de cada paciente
          _linhaRelatorio('Ana Clara', 0.70, '🔥 5 dias', Colors.orange),
          _linhaRelatorio('Pedro Henrique', 0.30, '🔥 2 dias', Colors.blue),
          _linhaRelatorio('Mariana Silva', 1.0, '🏆 Concluído!', Colors.green),
          _linhaRelatorio('Lucas Oliveira', 0.10, '⚠️ Sem prática', Colors.red),

          const SizedBox(height: 24),

          // ── Seção de trilhas mais usadas ─────────────────────
          const Text(
            'Trilhas Mais Praticadas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C),
            ),
          ),
          const SizedBox(height: 14),

          _linhaTrilha('🗣️ Trilha dos Fonemas', 0.65),
          const SizedBox(height: 10),
          _linhaTrilha('🌀 Trava-Línguas', 0.40),
        ],
      ),
    );
  }

  Widget _linhaRelatorio(
      String nome, double pct, String extra, Color cor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nome,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A148C),
                ),
              ),
              Text(
                extra,
                style: TextStyle(fontSize: 12, color: cor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE1BEE7),
                    valueColor: AlwaysStoppedAnimation<Color>(cor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(pct * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linhaTrilha(String titulo, double pct) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE1BEE7),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF7B2FBE)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(pct * 100).toInt()}% dos pacientes',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7B2FBE),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardRelatorio extends StatelessWidget {
  final String emoji;
  final String valor;
  final String rotulo;
  final Color cor;

  const _CardRelatorio({
    required this.emoji,
    required this.valor,
    required this.rotulo,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A148C),
              ),
            ),
            Text(
              rotulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ABA PERFIL — FONOAUDIÓLOGO
// ════════════════════════════════════════════════════════════
class _AbaPerfilFono extends StatelessWidget {
  final String emailFono;
  const _AbaPerfilFono({required this.emailFono});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7F6),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF7B2FBE), width: 3),
            ),
            child: const Center(
              child: Text('👩‍⚕️', style: TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            emailFono,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '👩‍⚕️ Fonoaudiólogo',
              style: TextStyle(
                color: Color(0xFF7B2FBE),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _itemPerfil(Icons.edit_outlined, 'Editar dados'),
          _itemPerfil(Icons.people_outlined, 'Gerenciar pacientes'),
          _itemPerfil(Icons.download_outlined, 'Exportar relatórios'),
          _itemPerfil(Icons.help_outline_rounded, 'Suporte'),
          _itemPerfil(Icons.info_outline_rounded, 'Sobre o Liri'),
        ],
      ),
    );
  }

  Widget _itemPerfil(IconData icone, String titulo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icone, color: const Color(0xFF7B2FBE)),
        title: Text(titulo,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing:
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}

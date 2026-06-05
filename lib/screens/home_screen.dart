import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/exercicio.dart';
import '../services/firestore_service.dart';
import 'exercicio_screen.dart';
import 'access_screen.dart';
import 'relatorios_screen.dart';

/// Tela inicial do paciente — agora mostra a LISTA de exercícios prescritos
/// pela fonoaudióloga (lidos do Firestore em tempo real), sem trilhas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.pacienteId});

  final String pacienteId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _nomePaciente = 'Amiguinho';

  @override
  void initState() {
    super.initState();
    _carregarNomePaciente();
  }

  Future<void> _carregarNomePaciente() async {
    final dados = await FirestoreService.instance.getDadosPaciente(widget.pacienteId);
    if (mounted && dados != null) {
      setState(() {
        _nomePaciente = (dados['nome'] as String?)?.split(' ').first ?? 'Amiguinho';
      });
    }
  }

  Future<void> _sair() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AccessScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5C6F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(_nomePaciente),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFFCF0FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: StreamBuilder<List<Exercicio>>(
                  stream: FirestoreService.instance
                      .streamExerciciosDoPaciente(widget.pacienteId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Erro ao carregar seus exercícios.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF7B2FBE)),
                          ),
                        ),
                      );
                    }
                    final exercicios = snapshot.data ?? [];
                    if (exercicios.isEmpty) {
                      return _estadoVazio();
                    }
                    return _buildListaExercicios(exercicios);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            // Já está na Home — não faz nada
            setState(() => _currentIndex = 0);
          } else if (index == 1) {
            // Relatório → abre a tela de relatórios
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RelatoriosScreen(pacienteId: widget.pacienteId),
              ),
            );
          } else if (index == 2) {
            // Perfil → menu de sair
            _abrirMenuPerfil();
          }
        },
        selectedItemColor: const Color(0xFF7B2FBE),
        unselectedItemColor: const Color(0xFFAA88CC),
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/home_nav_trilhas.png', width: 20),
            label: 'Exercícios',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/home_nav_relatorio.png', width: 20),
            label: 'Relatório',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/home_nav_perfil.png', width: 20),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  void _abrirMenuPerfil() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF7B2FBE)),
              title: Text(_nomePaciente,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Paciente'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF7B2FBE)),
              title: const Text('Sair'),
              onTap: () {
                Navigator.pop(context);
                _sair();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────
  Widget _buildHeader(String nome) {
    return SizedBox(
      height: 140,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            child: SvgPicture.asset(
              'assets/images/Prancheta4.svg',
              width: 145,
              fit: BoxFit.fitHeight,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 160, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá $nome,',
                    style: const TextStyle(
                      fontFamily: 'LeagueSpartan',
                      color: Color(0xFF7B2FBE),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    'O que vamos treinar hoje?',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      color: Color(0xFF7B2FBE),
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ESTADO VAZIO ────────────────────────────────────────────────────────
  Widget _estadoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🦒', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            const Text(
              'Nenhum exercício ainda!',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                color: Color(0xFF7B2FBE),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sua fonoaudióloga vai prescrever\nseus exercícios em breve. 🌟',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                color: const Color(0xFF7B2FBE).withOpacity(0.7),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LISTA DE EXERCÍCIOS ─────────────────────────────────────────────────
  Widget _buildListaExercicios(List<Exercicio> exercicios) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        // Card "Sua Sequência" — calcula com base no progresso real
        _CardSequencia(pacienteId: widget.pacienteId),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Seus exercícios',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                color: Color(0xFF7B2FBE),
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7B2FBE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${exercicios.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Stream dos exercícios concluídos para mostrar quais já foram feitos
        StreamBuilder<Set<String>>(
          stream: FirestoreService.instance
              .streamExerciciosConcluidos(widget.pacienteId),
          builder: (context, snap) {
            final concluidos = snap.data ?? <String>{};
            return Column(
              children: [
                for (int i = 0; i < exercicios.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CardExercicio(
                      exercicio: exercicios[i],
                      numero: i + 1,
                      concluido: concluidos.contains(exercicios[i].id),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExercicioScreen(
                              exercicio: exercicios[i],
                              pacienteId: widget.pacienteId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CardExercicio extends StatelessWidget {
  const _CardExercicio({
    required this.exercicio,
    required this.numero,
    required this.concluido,
    required this.onTap,
  });

  final Exercicio exercicio;
  final int numero;
  final bool concluido;
  final VoidCallback onTap;

  Color _corDificuldade() {
    switch (exercicio.dificuldade) {
      case 'fácil':         return const Color(0xFFB8F07A);
      case 'médio':         return const Color(0xFFFFC067);
      case 'difícil':       return const Color(0xFFFFB4DF);
      case 'personalizado': return const Color(0xFFC2B0FF);
      default:              return const Color(0xFFB8F07A);
    }
  }

  String _emojiDificuldade() {
    switch (exercicio.dificuldade) {
      case 'fácil':         return '🟢';
      case 'médio':         return '🟡';
      case 'difícil':       return '🔴';
      case 'personalizado': return '✏️';
      default:              return '⭐';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: concluido ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: concluido
                ? const Color(0xFF5CAD4E)
                : _corDificuldade(),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B2FBE).withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: concluido
                    ? const Color(0xFF5CAD4E)
                    : _corDificuldade(),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: concluido
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 28)
                    : Text(
                        '$numero',
                        style: const TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercicio.palavraAlvo,
                    style: const TextStyle(
                      fontFamily: 'LeagueSpartan',
                      color: Color(0xFF4A148C),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exercicio.instrucao,
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      color: const Color(0xFF7B2FBE).withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('${_emojiDificuldade()} ${exercicio.dificuldade}',
                          style: const TextStyle(fontSize: 12)),
                      if (exercicio.fonema.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE7F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            exercicio.fonema,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7B2FBE),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              concluido ? Icons.replay_rounded : Icons.chevron_right_rounded,
              color: const Color(0xFF7B2FBE),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// _CardSequencia — mostra os dias da semana praticados pelo
// paciente com base no histórico real do Firestore.
// =============================================================
class _CardSequencia extends StatelessWidget {
  const _CardSequencia({required this.pacienteId});

  final String pacienteId;

  /// Lê os progressos do paciente e devolve um Set com os dias da
  /// SEMANA ATUAL em que ele praticou (0 = domingo … 6 = sábado).
  Stream<Set<int>> _streamDiasPraticados() {
    return FirebaseFirestore.instance
        .collection('progresso_exercicios')
        .where('paciente_id', isEqualTo: pacienteId)
        .where('acertou', isEqualTo: true)
        .snapshots()
        .map((snap) {
      // Limite: início da semana (domingo 00:00) atual
      final agora = DateTime.now();
      final inicioSemana = DateTime(agora.year, agora.month, agora.day)
          .subtract(Duration(days: agora.weekday % 7));

      final dias = <int>{};
      for (final d in snap.docs) {
        final ts = d.data()['concluido_em'];
        if (ts is Timestamp) {
          final data = ts.toDate();
          if (data.isAfter(inicioSemana)) {
            dias.add(data.weekday % 7); // 0=dom, 1=seg, ... 6=sab
          }
        }
      }
      return dias;
    });
  }

  /// Conta quantos dias consecutivos terminando hoje o paciente praticou.
  int _calcularStreak(Set<int> diasPraticadosSemana) {
    final hoje = DateTime.now().weekday % 7;
    int streak = 0;
    for (int i = 0; i <= hoje; i++) {
      if (diasPraticadosSemana.contains(hoje - i)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']; // dom→sab

    return StreamBuilder<Set<int>>(
      stream: _streamDiasPraticados(),
      builder: (context, snap) {
        final dias    = snap.data ?? <int>{};
        final streak  = _calcularStreak(dias);
        final hoje    = DateTime.now().weekday % 7;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Sua Sequência',
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  color: Color(0xFF7B2FBE),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFB8F0C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Chama + número
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 4),
                      Text(
                        '$streak',
                        style: const TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7B2FBE),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Linha de dias
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (i) {
                        final ativo  = dias.contains(i);
                        final ehHoje = i == hoje;
                        return _DiaSemana(
                          letra: labels[i],
                          ativo: ativo,
                          ehHoje: ehHoje,
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DiaSemana extends StatelessWidget {
  const _DiaSemana({
    required this.letra,
    required this.ativo,
    required this.ehHoje,
  });

  final String letra;
  final bool ativo;
  final bool ehHoje;

  @override
  Widget build(BuildContext context) {
    final Color cor;
    final Color corTexto;
    if (ativo) {
      cor      = const Color(0xFFFFA94D); // laranja preenchido
      corTexto = Colors.white;
    } else {
      cor      = Colors.white;
      corTexto = ehHoje ? const Color(0xFF7B2FBE) : const Color(0xFFAA88CC);
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: cor,
        shape: BoxShape.circle,
        border: ehHoje && !ativo
            ? Border.all(color: const Color(0xFF7B2FBE), width: 1.5)
            : null,
      ),
      child: Center(
        child: Text(
          letra,
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: corTexto,
          ),
        ),
      ),
    );
  }
}

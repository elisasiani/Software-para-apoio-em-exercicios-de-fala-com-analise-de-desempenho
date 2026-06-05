// =============================================================
// relatorios_screen.dart
// Relatório de progresso do paciente logado.
//
// Mostra:
//   - Card grande de pontuação total (gamificação)
//   - Stats: exercícios feitos, palavras únicas, dias praticando
//   - Gráfico de barras: atividade dos últimos 7 dias
//   - Conquistas/medalhas desbloqueadas
//   - Histórico recente
//
// Pontuação por dificuldade:
//   fácil = 10 | médio = 20 | difícil = 30 | personalizado = 15
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'access_screen.dart';

class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key, required this.pacienteId});

  final String pacienteId;

  /// Lê todos os progressos do paciente em tempo real.
  Stream<QuerySnapshot> _streamProgressos() {
    return FirebaseFirestore.instance
        .collection('progresso_exercicios')
        .where('paciente_id', isEqualTo: pacienteId)
        .snapshots();
  }

  /// Pontos por dificuldade (mesma lógica do ExercicioScreen)
  int _pontosPorDificuldade(String d) {
    switch (d) {
      case 'fácil':         return 10;
      case 'médio':         return 20;
      case 'difícil':       return 30;
      case 'personalizado': return 15;
      default:              return 10;
    }
  }

  /// Para cada exercício, busca a dificuldade na prescrição relacionada.
  /// Em lote, faz um get por prescrição_id distinta.
  Future<Map<String, String>> _carregarDificuldades(
      Iterable<String> prescricaoIds) async {
    final result = <String, String>{};
    for (final id in prescricaoIds) {
      if (id.isEmpty) continue;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('prescricoes')
            .doc(id)
            .get();
        result[id] = (doc.data()?['dificuldade'] as String?) ?? 'fácil';
      } catch (_) {
        result[id] = 'fácil';
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5C6F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFFCF0FF),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _streamProgressos(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Erro ao carregar relatório.\n${snap.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF7B2FBE)),
                            ),
                          ),
                        );
                      }

                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) return _estadoVazio();

                      // Coleta IDs de prescrições para buscar dificuldades
                      final prescIds = docs
                          .map((d) =>
                              (d.data() as Map<String, dynamic>)['prescricao_id']
                                      as String? ??
                                  '')
                          .where((id) => id.isNotEmpty)
                          .toSet();

                      return FutureBuilder<Map<String, String>>(
                        future: _carregarDificuldades(prescIds),
                        builder: (context, snapDif) {
                          if (snapDif.connectionState == ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final dificuldades = snapDif.data ?? {};
                          return _buildRelatorio(docs, dificuldades);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // está na aba "Relatório"
        onTap: (index) {
          if (index == 0) {
            // Exercícios → volta pra Home (que está empilhada atrás)
            Navigator.pop(context);
          } else if (index == 1) {
            // Já está em Relatório, não faz nada
          } else if (index == 2) {
            // Perfil → abre o menu de sair
            _abrirMenuPerfil(context);
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

  // ── MENU DE PERFIL (igual ao da Home) ──────────────────────────────
  void _abrirMenuPerfil(BuildContext context) {
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
              leading: const Icon(Icons.logout, color: Color(0xFF7B2FBE)),
              title: const Text('Sair'),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AccessScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── HEADER (igual ao da Home, para consistência visual) ─────────────
  Widget _buildHeader() {
    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            child: SvgPicture.asset(
              'assets/images/Prancheta4.svg',
              width: 130,
              fit: BoxFit.fitHeight,
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 150, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seu progresso',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      color: Color(0xFF7B2FBE),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Veja como você está indo!',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      color: Color(0xFF7B2FBE),
                      fontSize: 18,
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

  // ── ESTADO VAZIO ────────────────────────────────────────────────────
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
              'Ainda sem dados!',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                color: Color(0xFF7B2FBE),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Faça alguns exercícios e veja\nseu progresso aqui. 🌟',
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

  // ── CORPO DO RELATÓRIO ──────────────────────────────────────────────
  Widget _buildRelatorio(
      List<QueryDocumentSnapshot> docs, Map<String, String> dificuldades) {
    // ── Calcula métricas ─────────────────────────────────────────────
    int totalExercicios = docs.length;
    int pontuacaoTotal = 0;
    final palavrasUnicas = <String>{};
    final diasUnicos = <String>{};
    final atividadePorDia = <int, int>{
      for (var i = 0; i < 7; i++) i: 0,
    };
    final palavraComMaisAcertos = <String, int>{};
    final hoje = DateTime.now();
    final inicio7dias =
        DateTime(hoje.year, hoje.month, hoje.day).subtract(const Duration(days: 6));

    for (final d in docs) {
      final dados = d.data() as Map<String, dynamic>;
      final prescId = dados['prescricao_id'] as String? ?? '';
      final dif = dificuldades[prescId] ?? 'fácil';
      pontuacaoTotal += _pontosPorDificuldade(dif);

      final palavra = dados['palavraAlvo'] as String? ?? '';
      if (palavra.isNotEmpty) {
        palavrasUnicas.add(palavra);
        palavraComMaisAcertos[palavra] =
            (palavraComMaisAcertos[palavra] ?? 0) + 1;
      }

      final ts = dados['concluido_em'];
      if (ts is Timestamp) {
        final data = ts.toDate();
        final chave =
            '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
        diasUnicos.add(chave);

        if (!data.isBefore(inicio7dias)) {
          // 0 = dom, 1 = seg, … 6 = sáb (igual ao streak da home)
          final indice = data.weekday % 7;
          atividadePorDia[indice] = (atividadePorDia[indice] ?? 0) + 1;
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      children: [
        _cardPontuacao(pontuacaoTotal),
        const SizedBox(height: 20),
        _gradeStats(
          totalExercicios: totalExercicios,
          palavrasUnicas: palavrasUnicas.length,
          diasAtivo: diasUnicos.length,
        ),
        const SizedBox(height: 24),
        _grafico7dias(atividadePorDia),
        const SizedBox(height: 24),
        _conquistas(
          totalExercicios: totalExercicios,
          pontuacao: pontuacaoTotal,
          diasAtivo: diasUnicos.length,
        ),
        const SizedBox(height: 24),
        _historicoRecente(docs),
      ],
    );
  }

  // ── CARD PONTUAÇÃO TOTAL ────────────────────────────────────────────
  Widget _cardPontuacao(int pontos) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFFA726)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 56)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sua pontuação',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pontos pts',
                  style: const TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 38,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Continue assim! 🚀',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── GRADE DE STATS ──────────────────────────────────────────────────
  Widget _gradeStats({
    required int totalExercicios,
    required int palavrasUnicas,
    required int diasAtivo,
  }) {
    return Row(
      children: [
        _statCard(
          icone: '🎯',
          valor: '$totalExercicios',
          rotulo: totalExercicios == 1 ? 'Exercício' : 'Exercícios',
          cor: const Color(0xFFE1BEE7),
        ),
        const SizedBox(width: 12),
        _statCard(
          icone: '📅',
          valor: '$diasAtivo',
          rotulo: diasAtivo == 1 ? 'Dia ativo' : 'Dias ativos',
          cor: const Color(0xFFC8E6C9),
        ),
      ],
    );
  }

  Widget _statCard({
    required String icone,
    required String valor,
    required String rotulo,
    required Color cor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor, width: 2),
        ),
        child: Column(
          children: [
            Text(icone, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              valor,
              style: const TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A148C),
              ),
            ),
            Text(
              rotulo,
              style: const TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 12,
                color: Color(0xFF7B2FBE),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── GRÁFICO 7 DIAS ──────────────────────────────────────────────────
  Widget _grafico7dias(Map<int, int> atividadePorDia) {
    const labels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    final hoje = DateTime.now().weekday % 7;
    final maximo = atividadePorDia.values.fold<int>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2FBE).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Atividade da semana',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              color: Color(0xFF4A148C),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final valor = atividadePorDia[i] ?? 0;
                final altura = maximo > 0 ? (valor / maximo) * 100 : 0.0;
                final ehHoje = i == hoje;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          valor > 0 ? '$valor' : '',
                          style: const TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7B2FBE),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: valor == 0 ? 6 : altura.clamp(12.0, 100.0),
                          decoration: BoxDecoration(
                            gradient: valor == 0
                                ? null
                                : LinearGradient(
                                    colors: ehHoje
                                        ? [
                                            const Color(0xFFFFB74D),
                                            const Color(0xFFFB8C00),
                                          ]
                                        : [
                                            const Color(0xFFCE93D8),
                                            const Color(0xFF7B2FBE),
                                          ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                            color: valor == 0
                                ? const Color(0xFFEDE7F6)
                                : null,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontSize: 12,
                            fontWeight: ehHoje
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: ehHoje
                                ? const Color(0xFF7B2FBE)
                                : const Color(0xFFAA88CC),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── CONQUISTAS / MEDALHAS ──────────────────────────────────────────
  Widget _conquistas({
    required int totalExercicios,
    required int pontuacao,
    required int diasAtivo,
  }) {
    final medalhas = <_Medalha>[
      _Medalha(
        emoji: '🌱',
        nome: 'Primeira vez',
        descricao: 'Fez seu primeiro exercício',
        desbloqueada: totalExercicios >= 1,
      ),
      _Medalha(
        emoji: '🔥',
        nome: 'Em chamas',
        descricao: 'Praticou em 3 dias diferentes',
        desbloqueada: diasAtivo >= 3,
      ),
      _Medalha(
        emoji: '⭐',
        nome: '100 pontos',
        descricao: 'Atingiu 100 pontos',
        desbloqueada: pontuacao >= 100,
      ),
      _Medalha(
        emoji: '🏆',
        nome: 'Dedicação',
        descricao: 'Completou 10 exercícios',
        desbloqueada: totalExercicios >= 10,
      ),
      _Medalha(
        emoji: '💎',
        nome: '500 pontos',
        descricao: 'Atingiu 500 pontos',
        desbloqueada: pontuacao >= 500,
      ),
      _Medalha(
        emoji: '👑',
        nome: 'Lenda',
        descricao: 'Completou 50 exercícios',
        desbloqueada: totalExercicios >= 50,
      ),
    ];

    final desbloqueadas = medalhas.where((m) => m.desbloqueada).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2FBE).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Suas conquistas',
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  color: Color(0xFF4A148C),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0B2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$desbloqueadas / ${medalhas.length}',
                  style: const TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF6C00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: medalhas.map(_buildMedalha).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMedalha(_Medalha m) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: m.desbloqueada
            ? const Color(0xFFFFF8E1)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: m.desbloqueada
              ? const Color(0xFFFFB74D)
              : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: m.desbloqueada ? 1.0 : 0.25,
            child: Text(m.emoji, style: const TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 4),
          Text(
            m.nome,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: m.desbloqueada
                  ? const Color(0xFF4A148C)
                  : const Color(0xFFBDBDBD),
            ),
          ),
          Text(
            m.descricao,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 9,
              color: m.desbloqueada
                  ? const Color(0xFF7B2FBE)
                  : const Color(0xFFBDBDBD),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── HISTÓRICO RECENTE ──────────────────────────────────────────────
  Widget _historicoRecente(List<QueryDocumentSnapshot> docs) {
    // Ordena por data desc
    final ordenados = [...docs];
    ordenados.sort((a, b) {
      final ta = ((a.data() as Map)['concluido_em'] as Timestamp?)
              ?.toDate()
              .millisecondsSinceEpoch ??
          0;
      final tb = ((b.data() as Map)['concluido_em'] as Timestamp?)
              ?.toDate()
              .millisecondsSinceEpoch ??
          0;
      return tb - ta;
    });
    final top5 = ordenados.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2FBE).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Atividades recentes',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              color: Color(0xFF4A148C),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...top5.map((d) {
            final dados = d.data() as Map<String, dynamic>;
            final palavra = dados['palavraAlvo'] as String? ?? '—';
            final ts = dados['concluido_em'];
            final quando = ts is Timestamp ? _tempoRelativo(ts.toDate()) : '—';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F0FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('🎤', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"$palavra"',
                          style: const TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A148C),
                          ),
                        ),
                        Text(
                          quando,
                          style: const TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontSize: 11,
                            color: Color(0xFF7B2FBE),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          if (top5.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Faça seu primeiro exercício para começar! 🌟',
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 13,
                  color: Color(0xFF7B2FBE),
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  String _tempoRelativo(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inMinutes < 1) return 'agora mesmo';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) {
      return 'há ${diff.inHours} ${diff.inHours == 1 ? 'hora' : 'horas'}';
    }
    if (diff.inDays < 7) {
      return 'há ${diff.inDays} ${diff.inDays == 1 ? 'dia' : 'dias'}';
    }
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}

class _Medalha {
  final String emoji;
  final String nome;
  final String descricao;
  final bool desbloqueada;

  _Medalha({
    required this.emoji,
    required this.nome,
    required this.descricao,
    required this.desbloqueada,
  });
}

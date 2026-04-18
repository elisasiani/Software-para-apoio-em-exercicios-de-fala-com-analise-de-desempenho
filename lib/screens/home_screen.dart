import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercicio.dart';
import '../models/user_progress.dart';
import '../widgets/mascote_widget.dart';
import 'trilha_screen.dart';

class HomeScreen extends StatelessWidget {
  final String nomeUsuario;

  const HomeScreen({super.key, this.nomeUsuario = 'Amiguinho'});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProgress>(
      builder: (context, progresso, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F0FF),
          appBar: AppBar(
            backgroundColor: const Color(0xFF7B2FBE),
            elevation: 0,
            title: const Text(
              'Liri 🦒',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            actions: [
              _BadgeResumo(
                icon: Icons.local_fire_department,
                value: '${progresso.streakDays}',
                color: Colors.orange,
              ),
              _BadgeResumo(
                icon: Icons.star_rounded,
                value: '${progresso.totalStars}',
                color: Colors.yellow,
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, $nomeUsuario! 👋',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'O que vamos treinar hoje?',
                    style: TextStyle(fontSize: 16, color: Color(0xFF9C27B0)),
                  ),
                  const SizedBox(height: 24),
                  const MascoteWidget(
                    mensagem:
                        'Pronta para treinar juntos! Escolha uma trilha! 🌟',
                    animacao: 'falando',
                  ),
                  const SizedBox(height: 28),
                  _CardProgresso(progresso: progresso),
                  const SizedBox(height: 24),
                  const Text(
                    'Suas Trilhas',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...DadosApp.trilhas.map(
                    (trilha) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _TrilhaCard(
                        trilha: trilha,
                        progresso: progresso.getProgressoTrilha(trilha.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BadgeResumo extends StatelessWidget {
  const _BadgeResumo({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardProgresso extends StatelessWidget {
  const _CardProgresso({required this.progresso});

  final UserProgress progresso;

  @override
  Widget build(BuildContext context) {
    final totalFeitos = DadosApp.trilhas
        .map((trilha) => progresso.getProgressoTrilha(trilha.id))
        .fold<int>(0, (soma, valor) => soma + valor);
    final totalPossivel = DadosApp.trilhas.fold<int>(
      0,
      (soma, trilha) => soma + trilha.exercicios.length,
    );
    final percentual = totalPossivel == 0 ? 0.0 : totalFeitos / totalPossivel;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B2FBE), Color(0xFFAB47BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2FBE).withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seu progresso total',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalFeitos de $totalPossivel exercícios',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(percentual * 100).round()}%',
                style: const TextStyle(
                  color: Colors.yellow,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentual,
              minHeight: 12,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellow),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrilhaCard extends StatelessWidget {
  const _TrilhaCard({required this.trilha, required this.progresso});

  final Trilha trilha;
  final int progresso;

  @override
  Widget build(BuildContext context) {
    final totalExercicios = trilha.exercicios.length;
    final concluida = progresso >= totalExercicios;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TrilhaScreen(trilha: trilha)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: concluida ? Colors.green : const Color(0xFFCE93D8),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(trilha.emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trilha.titulo,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trilha.subtitulo,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: totalExercicios == 0
                                ? 0
                                : progresso / totalExercicios,
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
                      const SizedBox(width: 10),
                      Text(
                        '$progresso/$totalExercicios',
                        style: TextStyle(
                          fontSize: 13,
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
            const SizedBox(width: 8),
            Icon(
              concluida
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: concluida ? Colors.green : const Color(0xFF9C27B0),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

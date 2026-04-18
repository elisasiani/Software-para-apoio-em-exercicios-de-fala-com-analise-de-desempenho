import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercicio.dart';
import '../models/user_progress.dart';
import '../widgets/mascote_widget.dart';
import 'trilha_screen.dart'; // <--- Verifique se este ficheiro não contém outra HomeScreen

class HomeScreen extends StatelessWidget {
  final String nomeUsuario;

  const HomeScreen({super.key, this.nomeUsuario = 'Amiguinho'});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProgress>(
      builder: (context, progresso, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F0FF),
          appBar: _buildAppBar(progresso),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, $nomeUsuario! 👋',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'O que vamos treinar hoje?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF9C27B0),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const MascoteWidget(
                    mensagem: 'Pronta para treinar juntos! Escolha uma trilha! 🌟',
                    animacao: 'falando',
                  ),
                  const SizedBox(height: 32),
                  _buildCardProgresso(progresso),
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
                  // A listagem dinâmica corrigida
                  ...DadosApp.trilhas.map(
                    (trilha) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildCartaoTrilha(context, trilha, progresso),
                    ),
                  ).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(UserProgress progresso) {
    return AppBar(
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
        _buildBadge(Icons.local_fire_department, '${progresso.streakDays}', Colors.orange),
        _buildBadge(Icons.star_rounded, '${progresso.totalStars}', Colors.yellow),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String valor, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cor, size: 26),
          const SizedBox(width: 3),
          Text(
            valor,
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

  Widget _buildCardProgresso(UserProgress progresso) {
    final totalFeitos = DadosApp.trilhas
        .map((t) => progresso.getProgressoTrilha(t.id))
        .fold(0, (soma, v) => soma + v);
    final totalPossivel = DadosApp.trilhas.length * 5;
    final percentual = totalPossivel > 0 ? totalFeitos / totalPossivel : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B2FBE), Color(0xFFAB47BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seu Progresso Total',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalFeitos de $totalPossivel exercícios',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '${(percentual * 100).toInt()}%',
                style: const TextStyle(color: Colors.yellow, fontSize: 22, fontWeight: FontWeight.bold),
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

  Widget _buildCartaoTrilha(BuildContext context, Trilha trilha, UserProgress progresso) {
    final progressoTrilha = progresso.getProgressoTrilha(trilha.id);
    final concluida = progressoTrilha >= 5;

    return GestureDetector(
      onTap: () {
        // Se ao clicar aqui ele abre a Home novamente, o problema está na classe 'TrilhaScreen'
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrilhaScreen(trilha: trilha),
          ),
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
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trilha.subtitulo,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progressoTrilha / 5,
                    backgroundColor: const Color(0xFFE1BEE7),
                    valueColor: AlwaysStoppedAnimation<Color>(concluida ? Colors.green : const Color(0xFF7B2FBE)),
                  ),
                ],
              ),
            ),
            Icon(
              concluida ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: concluida ? Colors.green : const Color(0xFF9C27B0),
            ),
          ],
        ),
      ),
    );
  }
}
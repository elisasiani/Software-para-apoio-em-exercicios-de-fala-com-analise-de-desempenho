import 'package:flutter/material.dart';
import 'welcome_screen2.dart';

// ==============================================================
// HOME DO FONOAUDIÓLOGO
// Tela simplificada que o fonoaudiólogo vê ao fazer login.
// Por enquanto mostra dados mockados (estáticos).
// No futuro, esses dados viriam do Firebase Firestore.
// ==============================================================
class HomeFonoScreen extends StatelessWidget {
  final String emailFono;

  const HomeFonoScreen({super.key, required this.emailFono});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B2FBE),
        title: const Text(
          'Liri — Fonoaudiólogo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        // Botão de sair: volta para a tela de login
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Sair',
            onPressed: () {
              // pushReplacement: substitui a tela atual pelo Login
              // o profissional não consegue voltar com o botão de voltar
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho de boas-vindas
            Container(
              width: double.infinity,
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
                    '👩‍⚕️ Bem-vinda(o)!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    emailFono,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Seus Pacientes',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A148C),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Acompanhe o progresso de cada criança',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // Lista de pacientes (dados mockados por enquanto)
            // TODO: buscar do Firebase Firestore futuramente
            _buildCartaoPaciente(
              nome: 'Ana Clara',
              exerciciosFeitos: 7,
              totalExercicios: 10,
              ultimaAtividade: 'Hoje',
              corProgresso: const Color(0xFF7B2FBE),
            ),
            const SizedBox(height: 12),
            _buildCartaoPaciente(
              nome: 'Pedro Henrique',
              exerciciosFeitos: 3,
              totalExercicios: 10,
              ultimaAtividade: 'Ontem',
              corProgresso: const Color(0xFFAB47BC),
            ),
            const SizedBox(height: 12),
            _buildCartaoPaciente(
              nome: 'Mariana Silva',
              exerciciosFeitos: 10,
              totalExercicios: 10,
              ultimaAtividade: 'Hoje',
              corProgresso: Colors.green,
            ),

            const SizedBox(height: 28),

            // Botão de adicionar paciente (sem funcionalidade por enquanto)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: implementar cadastro de paciente
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Função em desenvolvimento! 🚧'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.person_add_outlined, color: Color(0xFF7B2FBE)),
                label: const Text(
                  'Adicionar Paciente',
                  style: TextStyle(
                    color: Color(0xFF7B2FBE),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7B2FBE), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card de cada paciente na lista
  Widget _buildCartaoPaciente({
    required String nome,
    required int exerciciosFeitos,
    required int totalExercicios,
    required String ultimaAtividade,
    required Color corProgresso,
  }) {
    final percentual = exerciciosFeitos / totalExercicios;
    final completo = exerciciosFeitos >= totalExercicios;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completo ? Colors.green.shade200 : const Color(0xFFCE93D8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar com inicial do nome
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFEDE7F6),
            child: Text(
              nome[0], // Primeira letra do nome
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B2FBE),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A148C),
                      ),
                    ),
                    Text(
                      ultimaAtividade,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Barra de progresso do paciente
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percentual,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE1BEE7),
                    valueColor: AlwaysStoppedAnimation<Color>(corProgresso),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$exerciciosFeitos de $totalExercicios exercícios concluídos',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercicio.dart';
import '../models/user_progress.dart';
import '../widgets/mascote_widget.dart';
import '../widgets/trilha_node_widget.dart';
import 'exercicio_screen.dart';

class TrilhaScreen extends StatelessWidget {
  final Trilha trilha;

  const TrilhaScreen({super.key, required this.trilha});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProgress>(
      builder: (context, progresso, child) {
        // Buscamos o progresso específico desta trilha
        final int progressoAtual = progresso.getProgressoTrilha(trilha.id);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F0FF),
          appBar: AppBar(
            backgroundColor: const Color(0xFF7B2FBE),
            elevation: 0, // AppBar mais moderna e flat
            title: Text(
              trilha.titulo,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Column(
            children: [
              // Área do Mascote
              Padding(
                padding: const EdgeInsets.all(20),
                child: MascoteWidget(
                  mensagem: _getMensagemMascote(progressoAtual),
                  animacao: progressoAtual >= 5 ? 'comemorando' : 'falando',
                ),
              ),

              // Lista de Exercícios (Mapa)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 40, top: 10),
                  itemCount: trilha.exercicios.length,
                  itemBuilder: (context, index) {
                    // Inverte a ordem para o progresso subir (estilo Duolingo)
                    final int indexReal = trilha.exercicios.length - 1 - index;
                    final exercicio = trilha.exercicios[indexReal];
                    final int numeroNo = indexReal + 1;

                    // Lógica de estado do botão
                    EstadoNo estado;
                    if (indexReal < progressoAtual) {
                      estado = EstadoNo.completo;
                    } else if (indexReal == progressoAtual) {
                      estado = EstadoNo.disponivel;
                    } else {
                      estado = EstadoNo.bloqueado;
                    }

                    return _buildNodeItem(context, exercicio, numeroNo, estado);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Função auxiliar para organizar o código do Nó
  Widget _buildNodeItem(BuildContext context, dynamic exercicio, int numero, EstadoNo estado) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          TrilhaNodeWidget(
            numero: numero,
            estado: estado,
            onTap: estado == EstadoNo.bloqueado 
              ? null // Desativa o clique se estiver bloqueado
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExercicioScreen(
                        exercicio: exercicio,
                        trilhaId: trilha.id,
                        numeroExercicio: numero,
                        totalExercicios: trilha.exercicios.length,
                      ),
                    ),
                  );
                },
          ),
          const SizedBox(height: 8),
          Text(
            estado == EstadoNo.completo ? '✅ Concluído' : (estado == EstadoNo.disponivel ? 'Começar' : 'Bloqueado'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: estado == EstadoNo.bloqueado ? Colors.grey : const Color(0xFF4A148C),
            ),
          ),
        ],
      ),
    );
  }

  String _getMensagemMascote(int progresso) {
    if (progresso == 0) return 'Vamos começar essa jornada? 💪';
    if (progresso >= 5) return 'Uau! Trilha completada com sucesso! 🎉';
    return 'Você está indo muito bem! Continue! ⭐';
  }
}
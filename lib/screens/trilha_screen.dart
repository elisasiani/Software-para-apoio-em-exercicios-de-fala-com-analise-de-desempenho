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
    // Consumer: lê o UserProgress do Provider e reconstrói quando ele mudar
    return Consumer<UserProgress>(
      builder: (context, progresso, child) {
        final progressoAtual = progresso.getProgressoTrilha(trilha.id);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F0FF),
          appBar: AppBar(
            backgroundColor: const Color(0xFF7B2FBE),
            title: Text(
              trilha.titulo,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // Mascote no topo com mensagem contextual
              Padding(
                padding: const EdgeInsets.all(20),
                child: MascoteWidget(
                  mensagem: progressoAtual == 0
                      ? 'Vamos começar! Você consegue! 💪'
                      : progressoAtual == 5
                          ? 'Incrível! Você completou tudo! 🎉'
                          : 'Ótimo! Continue assim! ⭐',
                  animacao: progressoAtual == 5 ? 'comemorando' : 'falando',
                ),
              ),

              // Mapa da trilha com os nós
              Expanded(
                child: _buildMapaTrilha(context, progresso, progressoAtual),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapaTrilha(
      BuildContext context, UserProgress progresso, int progressoAtual) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20),
      // Os nós ficam na ordem inversa (o 1 embaixo, como no Duolingo)
      itemCount: trilha.exercicios.length,
      itemBuilder: (context, index) {
        // Invertemos o index para mostrar do mais recente pro mais antigo
        final indexReal = trilha.exercicios.length - 1 - index;
        final exercicio = trilha.exercicios[indexReal];
        final numeroNo = indexReal + 1;

        // Define o estado do nó baseado no progresso
        EstadoNo estado;
        if (indexReal < progressoAtual) {
          estado = EstadoNo.completo;
        } else if (indexReal == progressoAtual) {
          estado = EstadoNo.disponivel;
        } else {
          estado = EstadoNo.bloqueado;
        }

        // Alterna os nós para esquerda/direita (efeito zigue-zague do Duolingo)
        final alinhamento = indexReal % 2 == 0
            ? MainAxisAlignment.center
            : MainAxisAlignment.center;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            mainAxisAlignment: alinhamento,
            children: [
              Column(
                children: [
                  TrilhaNodeWidget(
                    numero: numeroNo,
                    estado: estado,
                    onTap: () {
                      // Navega para a tela do exercício
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExercicioScreen(
                            exercicio: exercicio,
                            trilhaId: trilha.id,
                            numeroExercicio: numeroNo,
                            totalExercicios: trilha.exercicios.length,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  // Rótulo abaixo do nó
                  Text(
                    estado == EstadoNo.completo
                        ? '✅ Feito!'
                        : estado == EstadoNo.disponivel
                            ? 'Exercício $numeroNo'
                            : '🔒',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: estado == EstadoNo.bloqueado
                          ? Colors.grey
                          : const Color(0xFF4A148C),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
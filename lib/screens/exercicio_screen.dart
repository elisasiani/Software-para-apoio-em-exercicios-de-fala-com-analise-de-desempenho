import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercicio.dart';
import '../models/user_progress.dart';
import '../widgets/mascote_widget.dart';

// Enum para os estados da gravação de voz
enum EstadoGravacao { esperando, gravando, processando, acerto, erro }

class ExercicioScreen extends StatefulWidget {
  final Exercicio exercicio;
  final String trilhaId;
  final int numeroExercicio;
  final int totalExercicios;

  const ExercicioScreen({
    super.key,
    required this.exercicio,
    required this.trilhaId,
    required this.numeroExercicio,
    required this.totalExercicios,
  });

  @override
  State<ExercicioScreen> createState() => _ExercicioScreenState();
}

class _ExercicioScreenState extends State<ExercicioScreen>
    with TickerProviderStateMixin {
  EstadoGravacao _estadoGravacao = EstadoGravacao.esperando;
  
  // AnimationController para o botão de microfone pulsar durante a gravação
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Começa pausado — só pulsa quando estiver gravando
    _pulseController.stop();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Simula a gravação de voz (placeholder para o pacote speech_to_text)
  Future<void> _iniciarGravacao() async {
    setState(() {
      _estadoGravacao = EstadoGravacao.gravando;
    });
    _pulseController.repeat(reverse: true);

    // =====================================================
    // TODO: Integrar pacote speech_to_text aqui
    // Passos futuros:
    // 1. Adicionar 'speech_to_text: ^6.6.0' no pubspec.yaml
    // 2. Pedir permissão de microfone (permission_handler)
    // 3. Iniciar escuta: stt.listen(onResult: _onSpeechResult)
    // 4. Em _onSpeechResult, comparar o texto reconhecido
    //    com widget.exercicio.palavraAlvo
    // =====================================================

    // Simulação de 2 segundos de "gravação"
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _estadoGravacao = EstadoGravacao.processando;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    // Simulação de resultado (50% de chance de acerto para testes)
    // SUBSTITUIR pela lógica real de reconhecimento de voz
    final bool acertou = DateTime.now().second % 2 == 0;
    
    _pulseController.stop();
    setState(() {
      _estadoGravacao = acertou ? EstadoGravacao.acerto : EstadoGravacao.erro;
    });

    if (acertou) {
      _mostrarDialogoSucesso();
    }
  }

  void _mostrarDialogoSucesso() {
    // Registra o progresso no UserProgress via Provider
    final progresso = Provider.of<UserProgress>(context, listen: false);
    progresso.completarExercicio(widget.trilhaId);

    // showDialog: exibe um popup por cima da tela atual
    showDialog(
      context: context,
      barrierDismissible: false, // Não fecha ao clicar fora
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFF3E5F5),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            const Text(
              'Arrasou!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A148C),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '+10 ⭐ estrelas!',
              style: TextStyle(fontSize: 18, color: Color(0xFF7B2FBE)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fecha o dialog
              Navigator.pop(context); // Volta para a trilha
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF7B2FBE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Próximo! 🚀',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B2FBE),
        title: Text(
          'Exercício ${widget.numeroExercicio} de ${widget.totalExercicios}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // Barra de progresso do exercício (XP bar estilo Duolingo)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: widget.numeroExercicio / widget.totalExercicios,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellow),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mascote com dica de animação
            MascoteWidget(
              mensagem: _getMensagemMascote(),
              animacao: _getAnimacaoMascote(),
            ),
            const SizedBox(height: 30),

            // Card com o exercício
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    widget.exercicio.instrucao,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '"${widget.exercicio.palavraAlvo}"',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Badge de dificuldade
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE7F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.exercicio.dificuldade.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B2FBE),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Feedback visual do estado
            _buildFeedbackEstado(),
            const SizedBox(height: 20),

            // Botão do microfone (coração do app)
            Center(
              child: ScaleTransition(
                scale: _estadoGravacao == EstadoGravacao.gravando
                    ? _pulseAnimation
                    : const AlwaysStoppedAnimation(1.0),
                child: GestureDetector(
                  onTap: _estadoGravacao == EstadoGravacao.esperando ||
                          _estadoGravacao == EstadoGravacao.erro
                      ? _iniciarGravacao
                      : null,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getCorBotaoMic(),
                      boxShadow: [
                        BoxShadow(
                          color: _getCorBotaoMic().withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                          ),
                          ],
                          ),
                          child: Icon(
                          _getIconeMic(),
                          color: Colors.white,
                          size: 44,
                          ),
                          ),
                          ),
                          ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                          child: Text(
                          _getLabelBotaoMic(),
                          style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7B2FBE),
                          fontWeight: FontWeight.w600,
                          ),
                          ),
                          ),
                          const SizedBox(height: 30),
                          ],
                          ),
                          ),
                          );
                          }

                          // Helpers para o estado visual dos componentes ↓

                          String _getMensagemMascote() {
                          switch (_estadoGravacao) {
                          case EstadoGravacao.esperando:
                          return 'Aperte o microfone e diga a palavra! 🎤';
                          case EstadoGravacao.gravando:
                          return 'Estou ouvindo... fala bem claro! 👂';
                          case EstadoGravacao.processando:
                          return 'Deixa eu pensar... 🤔';
                          case EstadoGravacao.acerto:
                          return 'Que incrível! Perfeito! 🎉';
                          case EstadoGravacao.erro:
                          return 'Quase! Tenta de novo, você consegue! 💪';
                          }
                          }

                          String _getAnimacaoMascote() {
                          switch (_estadoGravacao) {
                          case EstadoGravacao.acerto:
                          return 'comemorando';
                          case EstadoGravacao.gravando:
                          return 'falando';
                          default:
                          return 'idle';
                          }
                          }

                          Color _getCorBotaoMic() {
                          switch (_estadoGravacao) {
                          case EstadoGravacao.gravando:
                          return Colors.red;
                          case EstadoGravacao.acerto:
                          return Colors.green;
                          case EstadoGravacao.erro:
                          return Colors.orange;
                          default:
                          return const Color(0xFF7B2FBE);
                          }
                          }

                          IconData _getIconeMic() {
                          switch (_estadoGravacao) {
                          case EstadoGravacao.gravando:
                          return Icons.mic_rounded;
                          case EstadoGravacao.processando:
                          return Icons.hourglass_top_rounded;
                          case EstadoGravacao.acerto:
                          return Icons.check_rounded;
                          case EstadoGravacao.erro:
                          return Icons.refresh_rounded;
                          default:
                          return Icons.mic_none_rounded;
                          }
                          }

                          String _getLabelBotaoMic() {
                          switch (_estadoGravacao) {
                          case EstadoGravacao.gravando:
                          return 'Gravando...';
                          case EstadoGravacao.processando:
                          return 'Processando...';
                          case EstadoGravacao.acerto:
                          return 'Mandou bem! ⭐';
                          case EstadoGravacao.erro:
                          return 'Tente de novo';
                          default:
                          return 'Toque para falar';
                          }
                          }

                          Widget _buildFeedbackEstado() {
                          if (_estadoGravacao == EstadoGravacao.esperando ||
                          _estadoGravacao == EstadoGravacao.processando) {
                          return const SizedBox.shrink(); // Nada para mostrar
                          }

                          final isAcerto = _estadoGravacao == EstadoGravacao.acerto;

                          return AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          decoration: BoxDecoration(
                          color: isAcerto
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                          color: isAcerto ? Colors.green : Colors.orange,
                          width: 2,
                          ),
                          ),      child: Text(
        isAcerto
            ? '✅ Ótima pronúncia! Continue assim!'
            : '🔁 Não desista! Ouça a dica da Girafa e tente novamente.',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: isAcerto ? Colors.green.shade800 : Colors.orange.shade800,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
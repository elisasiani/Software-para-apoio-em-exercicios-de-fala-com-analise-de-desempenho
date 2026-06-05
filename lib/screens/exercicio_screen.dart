// =============================================================
// exercicio_screen.dart
// Tela de execução de exercício pelo paciente.
//
// Fluxo:
//   1. Mostra a palavra-alvo e instrução
//   2. Paciente aperta o botão grande do microfone
//   3. Gravação rola por 10 segundos (com contagem regressiva)
//   4. Áudio é convertido em base64 e enviado pro Firestore
//   5. Mensagem motivacional (gamificação): "Parabéns, continue assim!"
// =============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercicio.dart';
import '../models/user_progress.dart';
import '../services/audio_service.dart';
import '../services/firestore_service.dart';

enum EstadoGravacao { esperando, gravando, enviando, sucesso, erro }

class ExercicioScreen extends StatefulWidget {
  final Exercicio exercicio;
  final String pacienteId;

  const ExercicioScreen({
    super.key,
    required this.exercicio,
    required this.pacienteId,
  });

  @override
  State<ExercicioScreen> createState() => _ExercicioScreenState();
}

class _ExercicioScreenState extends State<ExercicioScreen>
    with TickerProviderStateMixin {
  EstadoGravacao _estado = EstadoGravacao.esperando;
  int _tentativas = 0;
  int _segundosRestantes = 10;
  Timer? _timer;
  String? _mensagemErro; // ← NOVO: mostra o erro na tela pra debug

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;

  // Mensagens motivacionais aleatórias (gamificação)
  static const _mensagensMotivacionais = [
    '🌟 Parabéns! Continue assim, você está indo super bem!',
    '🎉 Mandou muito bem! Sua fono vai amar ouvir isso!',
    '🚀 Que voz incrível! Você é demais!',
    '💪 Você está cada dia melhor! Continue assim!',
    '⭐ Excelente! Sua dedicação é inspiradora!',
    '🦒 A girafa adorou! Continue praticando!',
    '🌈 Que orgulho de você! Você é uma estrela!',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _timer?.cancel();
    AudioService.instance.cancelarGravacao();
    super.dispose();
  }

  // ── INICIAR GRAVAÇÃO ────────────────────────────────────────────────
  Future<void> _iniciarGravacao() async {
    try {
      await AudioService.instance.iniciarGravacao();
    } catch (e) {
      if (!mounted) return;
      _mostrarErroPermissao();
      return;
    }

    _tentativas++;
    setState(() {
      _estado = EstadoGravacao.gravando;
      _segundosRestantes = 10;
      _mensagemErro = null; // limpa erro anterior
    });

    _pulseController.repeat(reverse: true);
    _waveController.repeat();

    // Contagem regressiva — para sozinho quando chegar a 0
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _segundosRestantes--);

      if (_segundosRestantes <= 0) {
        timer.cancel();
        _finalizarGravacao();
      }
    });
  }

  // ── FINALIZAR E ENVIAR ──────────────────────────────────────────────
  Future<void> _finalizarGravacao() async {
    _timer?.cancel();
    _pulseController.stop();
    _waveController.stop();

    setState(() => _estado = EstadoGravacao.enviando);

    try {
      final base64 = await AudioService.instance.pararEObterBase64();
      if (base64 == null) {
        debugPrint('[Liri] base64 retornou null');
        if (mounted) {
          setState(() {
            _estado = EstadoGravacao.erro;
            _mensagemErro = 'O áudio ficou vazio. Tenta gravar de novo.';
          });
        }
        return;
      }

      // Loga o tamanho pra debug
      final tamanhoKB = (base64.length / 1024).toStringAsFixed(1);
      debugPrint('[Liri] Áudio gerado: ${tamanhoKB} KB em base64');

      // Verificação preventiva: 900 KB de base64 é nosso limite seguro
      // (Firestore aceita até 1 MB por doc, considerando os outros campos)
      if (base64.length > 900 * 1024) {
        if (mounted) {
          setState(() {
            _estado = EstadoGravacao.erro;
            _mensagemErro = 'Áudio muito grande (${tamanhoKB} KB). Tenta gravar menos tempo.';
          });
        }
        return;
      }

      // Envia para o Firestore
      await FirestoreService.instance.registrarConclusaoExercicio(
        pacienteId:     widget.pacienteId,
        profissionalId: widget.exercicio.profissionalId,
        prescricaoId:   widget.exercicio.id,
        palavraAlvo:    widget.exercicio.palavraAlvo,
        acertou:        true,
        tentativas:     _tentativas,
        audioBase64:    base64,
      );

      if (mounted) {
        Provider.of<UserProgress>(context, listen: false)
            .completarExercicio(widget.exercicio.categoria);
        setState(() => _estado = EstadoGravacao.sucesso);
        _mostrarDialogoMotivacional();
      }
    } catch (e, stack) {
      debugPrint('[Liri] Erro ao enviar áudio: $e');
      debugPrint('[Liri] Stack: $stack');
      if (mounted) {
        setState(() {
          _estado = EstadoGravacao.erro;
          _mensagemErro = e.toString();
        });
      }
    }
  }

  // ── DIÁLOGO MOTIVACIONAL (gamificação) ──────────────────────────────
  void _mostrarDialogoMotivacional() {
    // Faz uma CÓPIA da lista antes de embaralhar (a original é const/imutável)
    final lista = [..._mensagensMotivacionais]..shuffle();
    final msg = lista.first;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: const Color(0xFFFFF8E1),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Girafa comemorando
              AnimatedScale(
                scale: 1.0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🦒', style: TextStyle(fontSize: 62)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Áudio enviado!',
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A148C),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 15,
                  color: Color(0xFF7B2FBE),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0B2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      '+${_pontosDoExercicio()} estrelas',
                      style: const TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF6C00),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B2FBE),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Próximo exercício 🚀',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarErroPermissao() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Precisamos da permissão do microfone para gravar 🎤',
          style: TextStyle(fontFamily: 'LeagueSpartan'),
        ),
        backgroundColor: const Color(0xFF7B2FBE),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF0FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildCabecalho(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  children: [
                    _buildMascote(),
                    const SizedBox(height: 20),
                    _buildCardPalavra(),
                    const SizedBox(height: 32),
                    _buildAreaGravacao(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cabeçalho roxo com botão voltar
  Widget _buildCabecalho() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF5C6F5),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF7B2FBE)),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.exercicio.categoria.isNotEmpty
                  ? widget.exercicio.categoria
                  : 'Exercício',
              style: const TextStyle(
                fontFamily: 'LeagueSpartan',
                color: Color(0xFF7B2FBE),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mascote girafa com mensagem
  Widget _buildMascote() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE5B4), Color(0xFFFFD7E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🦒', style: TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _mensagemMascote(),
              style: const TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 14,
                color: Color(0xFF4A148C),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card central com a palavra
  Widget _buildCardPalavra() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2FBE).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _corDificuldade().withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_emojiDificuldade()} ${widget.exercicio.dificuldade.toUpperCase()}',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _corDificuldade(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.exercicio.instrucao,
            style: const TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 15,
              color: Color(0xFF7B2FBE),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.exercicio.palavraAlvo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // Área central com o botão de microfone (estado-dependente)
  Widget _buildAreaGravacao() {
    return Column(
      children: [
        // Indicador de gravação / contador
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildIndicadorEstado(),
        ),
        const SizedBox(height: 20),

        // Botão grande do microfone
        GestureDetector(
          onTap: () {
            if (_estado == EstadoGravacao.esperando ||
                _estado == EstadoGravacao.erro) {
              _iniciarGravacao();
            } else if (_estado == EstadoGravacao.gravando) {
              _finalizarGravacao();
            }
          },
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = _estado == EstadoGravacao.gravando
                  ? _pulseAnimation.value
                  : 1.0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Ondas de áudio quando gravando
                  if (_estado == EstadoGravacao.gravando) _buildOndas(),

                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _coresBotao(),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _coresBotao().first.withOpacity(0.45),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        _iconeBotao(),
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        Text(
          _labelBotao(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'LeagueSpartan',
            fontSize: 15,
            color: Color(0xFF7B2FBE),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildIndicadorEstado() {
    if (_estado == EstadoGravacao.gravando) {
      return Container(
        key: const ValueKey('contador'),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.shade300, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Gravando... ${_segundosRestantes}s',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (_estado == EstadoGravacao.enviando) {
      return Container(
        key: const ValueKey('enviando'),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF7B2FBE),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Enviando seu áudio...',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 14,
                color: Color(0xFF7B2FBE),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_estado == EstadoGravacao.erro) {
      return Container(
        key: const ValueKey('erro'),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ops! Tenta de novo? 🔁',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
            if (_mensagemErro != null) ...[
              const SizedBox(height: 8),
              Text(
                _mensagemErro!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 11,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return const SizedBox(key: ValueKey('vazio'), height: 0);
  }

  // Ondas decorativas em volta do mic enquanto grava
  Widget _buildOndas() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final value = _waveController.value;
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(3, (i) {
              final delay = i * 0.33;
              final t = (value + delay) % 1.0;
              return Opacity(
                opacity: (1 - t) * 0.5,
                child: Container(
                  width: 110 + (90 * t),
                  height: 110 + (90 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.shade300,
                      width: 2,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ── Helpers de UI ───────────────────────────────────────────────────
  String _mensagemMascote() {
    switch (_estado) {
      case EstadoGravacao.esperando:
        return 'Aperte o microfone e diga a palavra bem clarinho! 🎤';
      case EstadoGravacao.gravando:
        return 'Estou ouvindo! Fala bem alto e claro 👂✨';
      case EstadoGravacao.enviando:
        return 'Mandando pra sua fono... aguenta aí! 📨';
      case EstadoGravacao.sucesso:
        return 'Que voz incrível! 🌟';
      case EstadoGravacao.erro:
        return 'Ué, deu um probleminha. Tenta de novo! 💪';
    }
  }

  List<Color> _coresBotao() {
    switch (_estado) {
      case EstadoGravacao.gravando:
        return [Colors.red.shade400, Colors.red.shade700];
      case EstadoGravacao.enviando:
        return [const Color(0xFFB39DDB), const Color(0xFF7B2FBE)];
      case EstadoGravacao.sucesso:
        return [Colors.green.shade400, Colors.green.shade700];
      case EstadoGravacao.erro:
        return [Colors.orange.shade400, Colors.orange.shade700];
      default:
        return [const Color(0xFFB39DDB), const Color(0xFF7B2FBE)];
    }
  }

  IconData _iconeBotao() {
    switch (_estado) {
      case EstadoGravacao.gravando: return Icons.stop_rounded;
      case EstadoGravacao.enviando: return Icons.cloud_upload_rounded;
      case EstadoGravacao.sucesso:  return Icons.check_rounded;
      case EstadoGravacao.erro:     return Icons.refresh_rounded;
      default:                      return Icons.mic_rounded;
    }
  }

  String _labelBotao() {
    switch (_estado) {
      case EstadoGravacao.gravando: return 'Toque para parar antes';
      case EstadoGravacao.enviando: return 'Quase lá...';
      case EstadoGravacao.sucesso:  return 'Áudio enviado! 🎉';
      case EstadoGravacao.erro:     return 'Toque para tentar de novo';
      default:                      return 'Toque para falar (10s)';
    }
  }

  Color _corDificuldade() {
    switch (widget.exercicio.dificuldade) {
      case 'fácil':         return const Color(0xFF66BB6A);
      case 'médio':         return const Color(0xFFFFA726);
      case 'difícil':       return const Color(0xFFEF5350);
      case 'personalizado': return const Color(0xFF7E57C2);
      default:              return const Color(0xFF66BB6A);
    }
  }

  String _emojiDificuldade() {
    switch (widget.exercicio.dificuldade) {
      case 'fácil':         return '🟢';
      case 'médio':         return '🟡';
      case 'difícil':       return '🔴';
      case 'personalizado': return '✏️';
      default:              return '⭐';
    }
  }

  /// Pontuação ganha ao concluir o exercício, conforme dificuldade.
  /// Mesma lógica usada na tela de Relatórios para calcular o total.
  int _pontosDoExercicio() {
    switch (widget.exercicio.dificuldade) {
      case 'fácil':         return 10;
      case 'médio':         return 20;
      case 'difícil':       return 30;
      case 'personalizado': return 15;
      default:              return 10;
    }
  }
}

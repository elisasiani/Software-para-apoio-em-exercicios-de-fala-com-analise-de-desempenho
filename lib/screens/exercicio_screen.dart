import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/exercicio.dart';
import '../models/user_progress.dart';
import '../services/firestore_service.dart';
import '../widgets/mascote_widget.dart';
import 'package:record/record.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart'; // Para achar uma pasta temporária no celular
import 'dart:io';// Para manipular o arquivo de áudio

// Enum para os estados da gravação de voz
enum EstadoGravacao { esperando, gravando, processando, acerto, erro }

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
  EstadoGravacao _estadoGravacao = EstadoGravacao.esperando;
  int _tentativas = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  //Aqui foi adicionado a variável do TTS para conseguir ouvir a palavra antes de repetir
  final FlutterTts _flutterTts = FlutterTts();

  // criando a var que é a instância do gravador e a var que vai guardar o caminho do aúdio
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _caminhoAudioLocal;

  Future<void> _ouvirExemplo() async {
    // Configura para português do Brasil
    await _flutterTts.setLanguage("pt-BR");
    // set.SpeechRate define a velocidade da voz
    await _flutterTts.setSpeechRate(0.6); 
    // setPitch é o que deixa mais suave/feminino ou não
    await _flutterTts.setPitch(1.2);
    // Faz o celular falar a palavra que veio do banco de dados
    await _flutterTts.speak(widget.exercicio.palavraAlvo);
  }

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

    _pulseController.stop();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // 1. INICIA A GRAVAÇÃO REAL DO MICROFONE
  Future<void> _iniciarGravacao() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // Define um local temporário no celular para salvar o arquivo de áudio antes do upload
        final pastaTemp = await getTemporaryDirectory();
        final caminhoCompleto = '${pastaTemp.path}/audio_tcc_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc), 
          path: caminhoCompleto
        );

        setState(() {
          _estadoGravacao = EstadoGravacao.gravando;
        });
        _pulseController.repeat(reverse: true);
        _tentativas++;
      }
    } catch (e) {
      debugPrint('Erro ao iniciar gravação: $e');
    }
  }

  // 2. PARA A GRAVAÇÃO E FAZ O PROCESSO DE ENVIO
  Future<void> _pararEEnviarGravacao() async {
    try {
      final caminhoArquivoLocal = await _audioRecorder.stop();
      _pulseController.stop();

      if (caminhoArquivoLocal != null) {
        setState(() => _estadoGravacao = EstadoGravacao.processando);

        // Envia o arquivo para o Firebase Storage e pega o link de retorno
        String urlAudioFirebase = await _uploadAudioParaFirebase(caminhoArquivoLocal);

        // Salva os dados no Firestore (Dica: avise as meninas para adicionarem o campo urlAudio no método delas se necessário)
        await FirestoreService.instance.registrarConclusaoExercicio(
          pacienteId:     widget.pacienteId,
          profissionalId: widget.exercicio.profissionalId,
          prescricaoId:   widget.exercicio.id,
          palavraAlvo:    widget.exercicio.palavraAlvo,
          acertou:        true, // Sempre verdadeiro para a criança, pois ela concluiu o envio!
          tentativas:     _tentativas,
          urlAudio:    urlAudioFirebase, //Adiciona a url da voz do microfone ao firebase
        );

        setState(() => _estadoGravacao = EstadoGravacao.acerto);

        if (mounted) {
          _mostrarDialogoSucesso();
        }
      }
    } catch (e) {
      setState(() => _estadoGravacao = EstadoGravacao.erro);
      debugPrint('Erro ao parar ou enviar gravação: $e');
    }
  }

  // 3. FAZ O UPLOAD DO ARQUIVO .M4A PARA O STORAGE
  Future<String> _uploadAudioParaFirebase(String caminhoLocal) async {
    File arquivo = File(caminhoLocal);
    String nomeArquivo = "audio_${widget.pacienteId}_${DateTime.now().millisecondsSinceEpoch}.m4a";
    
    // Cria a referência da pasta dentro do Firebase Storage
    Reference ref = FirebaseStorage.instance.ref().child('audios_exercicios').child(nomeArquivo);
    
    UploadTask uploadTask = ref.putFile(arquivo);
    TaskSnapshot snapshot = await uploadTask;
    
    // Retorna a URL pública do áudio para a fonoaudióloga escutar na Web
    return await snapshot.ref.getDownloadURL();
  }

  void _mostrarDialogoSucesso() {
    // Mantém o UserProgress local para feedback imediato (streak/estrelas)
    final progresso = Provider.of<UserProgress>(context, listen: false);
    progresso.completarExercicio(widget.exercicio.categoria);

    showDialog(
      context: context,
      barrierDismissible: false,
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
              Navigator.pop(context); // Volta para a Home
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
          widget.exercicio.categoria.isNotEmpty
              ? widget.exercicio.categoria
              : 'Exercício',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MascoteWidget(
                mensagem: _getMensagemMascote(),
                animacao: _getAnimacaoMascote(),
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      widget.exercicio.instrucao,
                      style: const TextStyle(fontSize: 18, color: Colors.black54),
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
                    const SizedBox(height: 12),

                    // O botão está sendo implementado aqui para ouvir a voz falando a palavra
                    ElevatedButton.icon(
                      onPressed: _ouvirExemplo,
                      icon: const Icon(Icons.volume_up_rounded),
                      label: const Text('Ouvir Exemplo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEDE7F6),
                        foregroundColor: const Color(0xFF7B2FBE),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ---------------------------------

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

              _buildFeedbackEstado(),
              const SizedBox(height: 20),

              Center(
                child: ScaleTransition(
                  scale: _estadoGravacao == EstadoGravacao.gravando
                      ? _pulseAnimation
                      : const AlwaysStoppedAnimation(1.0),
                  child: GestureDetector(
                    // COMO DEVE FICAR:
                    onTap: () {
                      if (_estadoGravacao == EstadoGravacao.esperando || _estadoGravacao == EstadoGravacao.erro) {
                        _iniciarGravacao();
                      } else if (_estadoGravacao == EstadoGravacao.gravando) {
                        _pararEEnviarGravacao();
                      }
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getCorBotaoMic(),
                        boxShadow: [
                          BoxShadow(
                            color: _getCorBotaoMic().withOpacity(0.4),
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
      ),
    );
  }

  // ── Helpers visuais ───────────────────────────────────────────────────────
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
      case EstadoGravacao.acerto:   return 'comemorando';
      case EstadoGravacao.gravando: return 'falando';
      default:                      return 'idle';
    }
  }

  Color _getCorBotaoMic() {
    switch (_estadoGravacao) {
      case EstadoGravacao.gravando: return Colors.red;
      case EstadoGravacao.acerto:   return Colors.green;
      case EstadoGravacao.erro:     return Colors.orange;
      default:                      return const Color(0xFF7B2FBE);
    }
  }

  IconData _getIconeMic() {
    switch (_estadoGravacao) {
      case EstadoGravacao.gravando:     return Icons.mic_rounded;
      case EstadoGravacao.processando:  return Icons.hourglass_top_rounded;
      case EstadoGravacao.acerto:       return Icons.check_rounded;
      case EstadoGravacao.erro:         return Icons.refresh_rounded;
      default:                          return Icons.mic_none_rounded;
    }
  }

  String _getLabelBotaoMic() {
    switch (_estadoGravacao) {
      case EstadoGravacao.gravando:    return 'Gravando...';
      case EstadoGravacao.processando: return 'Processando...';
      case EstadoGravacao.acerto:      return 'Mandou bem! ⭐';
      case EstadoGravacao.erro:        return 'Tente de novo';
      default:                         return 'Toque para falar';
    }
  }

  Widget _buildFeedbackEstado() {
    if (_estadoGravacao == EstadoGravacao.esperando ||
        _estadoGravacao == EstadoGravacao.processando) {
      return const SizedBox.shrink();
    }
    final isAcerto = _estadoGravacao == EstadoGravacao.acerto;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: isAcerto
            ? Colors.green.withOpacity(0.15)
            : Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAcerto ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Text(
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

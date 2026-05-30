// =============================================================
// audio_service.dart
// Serviço responsável por:
//   1. Pedir permissão do microfone
//   2. Gravar áudio em arquivo temporário (.m4a 32kbps mono)
//   3. Ler o arquivo gerado e devolver em base64
//
// O áudio em base64 é salvo direto no Firestore (sem Storage),
// como uma string dentro do doc de progresso_exercicios.
// =============================================================

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioRecorder _recorder = AudioRecorder();
  String? _caminhoArquivo;

  /// Pede permissão do microfone. Retorna true se concedida.
  Future<bool> pedirPermissaoMicrofone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Inicia a gravação em arquivo temporário.
  Future<void> iniciarGravacao() async {
    final permitido = await pedirPermissaoMicrofone();
    if (!permitido) {
      throw Exception('Permissão de microfone negada');
    }

    final tempDir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    _caminhoArquivo = '${tempDir.path}/liri_audio_$ts.m4a';

    // Configuração: AAC-LC, 32 kbps, mono, 16 kHz
    // Saída ~40 KB para 10 segundos — cabe no limite de 1 MB do Firestore.
    await _recorder.start(
      const RecordConfig(
        encoder:    AudioEncoder.aacLc,
        bitRate:    32000,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _caminhoArquivo!,
    );
  }

  /// Para a gravação e devolve o áudio em base64.
  /// Retorna null se algo der errado.
  Future<String?> pararEObterBase64() async {
    final path = await _recorder.stop();
    final arquivoFinal = path ?? _caminhoArquivo;
    if (arquivoFinal == null) return null;

    final file = File(arquivoFinal);
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();

    // Limpa o arquivo temporário (já temos os bytes em memória)
    try { await file.delete(); } catch (_) {}

    return base64Encode(bytes);
  }

  /// Cancela a gravação (descarta o arquivo).
  Future<void> cancelarGravacao() async {
    await _recorder.cancel();
    if (_caminhoArquivo != null) {
      try { await File(_caminhoArquivo!).delete(); } catch (_) {}
    }
  }

  Future<bool> estaGravando() => _recorder.isRecording();
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercicio.dart';

/// Camada de acesso ao Firestore.
/// Centraliza todas as queries — telas não conhecem o Firestore diretamente.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  // ── PACIENTE ──────────────────────────────────────────────────────────────

  /// Busca os dados do paciente logado (nome, etc.).
  Future<Map<String, dynamic>?> getDadosPaciente(String uid) async {
    final doc = await _db.collection('pacientes').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  // ── EXERCÍCIOS PRESCRITOS ─────────────────────────────────────────────────

  /// Stream em TEMPO REAL dos exercícios prescritos ao paciente.
  /// Sempre que a fonoaudióloga adicionar/remover um exercício no web,
  /// o app mobile atualiza automaticamente.
  Stream<List<Exercicio>> streamExerciciosDoPaciente(String pacienteId) {
    return _db
        .collection('prescricoes')
        .where('paciente_id', isEqualTo: pacienteId)
        .where('ativo', isEqualTo: true)
        .orderBy('data_prescricao', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Exercicio.fromFirestore).toList());
  }

  /// Versão one-shot (sem stream) — útil para refresh manual.
  Future<List<Exercicio>> getExerciciosDoPaciente(String pacienteId) async {
    final snap = await _db
        .collection('prescricoes')
        .where('paciente_id', isEqualTo: pacienteId)
        .where('ativo', isEqualTo: true)
        .orderBy('data_prescricao', descending: true)
        .get();
    return snap.docs.map(Exercicio.fromFirestore).toList();
  }

  // ── PROGRESSO ────────────────────────────────────────────────────────────

  /// Registra a conclusão de um exercício pelo paciente.
  Future<void> registrarConclusaoExercicio({
    required String pacienteId,
    required String profissionalId,
    required String prescricaoId,
    required String palavraAlvo,
    required bool acertou,
    int tentativas = 1,
    required String urlAudio,
  }) async {
    await _db.collection('progresso_exercicios').add({
      'paciente_id':     pacienteId,
      'profissional_id': profissionalId,
      'prescricao_id':   prescricaoId,
      'palavraAlvo':     palavraAlvo,
      'acertou':         acertou,
      'tentativas':      tentativas,
      'concluido_em':    FieldValue.serverTimestamp(),
      'urlAudio': urlAudio,
    });
  }

  /// IDs dos exercícios que o paciente já concluiu (acertou).
  Future<Set<String>> getExerciciosConcluidos(String pacienteId) async {
    final snap = await _db
        .collection('progresso_exercicios')
        .where('paciente_id', isEqualTo: pacienteId)
        .where('acertou', isEqualTo: true)
        .get();
    return snap.docs
        .map((d) => (d.data()['prescricao_id'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  /// Stream dos IDs concluídos (para a tela atualizar quando o paciente conclui).
  Stream<Set<String>> streamExerciciosConcluidos(String pacienteId) {
    return _db
        .collection('progresso_exercicios')
        .where('paciente_id', isEqualTo: pacienteId)
        .where('acertou', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => (d.data()['prescricao_id'] as String?) ?? '')
            .where((id) => id.isNotEmpty)
            .toSet());
  }
}

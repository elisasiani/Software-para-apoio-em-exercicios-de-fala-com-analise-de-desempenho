import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa um exercício prescrito por um profissional a um paciente.
/// Espelha o documento da coleção `prescricoes` no Firestore.
class Exercicio {
  final String id;              // ID do documento no Firestore
  final String pacienteId;
  final String profissionalId;
  final String palavraAlvo;     // O que o paciente deve falar
  final String instrucao;       // "Diga bem devagar:"
  final String dicaAnimacao;    // Descrição da animação da girafa
  final String dificuldade;     // 'fácil' | 'médio' | 'difícil' | 'personalizado'
  final String categoria;       // trilha_titulo (ex: "Trilha dos Fonemas")
  final String tipo;            // 'fonema' | 'frase' | 'custom'
  final String fonema;          // '/r/' etc.
  final DateTime? dataPrescricao;
  final bool ativo;

  const Exercicio({
    required this.id,
    required this.pacienteId,
    required this.profissionalId,
    required this.palavraAlvo,
    required this.instrucao,
    this.dicaAnimacao = '',
    this.dificuldade = 'fácil',
    this.categoria = '',
    this.tipo = '',
    this.fonema = '',
    this.dataPrescricao,
    this.ativo = true,
  });

  /// Constrói a partir de um DocumentSnapshot do Firestore.
  factory Exercicio.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Exercicio(
      id:              doc.id,
      pacienteId:      data['paciente_id']     ?? '',
      profissionalId:  data['profissional_id'] ?? '',
      palavraAlvo:     data['palavraAlvo']     ?? '',
      instrucao:       data['instrucao']       ?? 'Diga:',
      dicaAnimacao:    data['dicaAnimacao']    ?? '',
      dificuldade:     data['dificuldade']     ?? 'fácil',
      categoria:       data['trilha_titulo']   ?? '',
      tipo:            data['trilha_tipo']     ?? '',
      fonema:          data['trilha_fonema']   ?? '',
      dataPrescricao:  (data['data_prescricao'] as Timestamp?)?.toDate(),
      ativo:           data['ativo'] ?? true,
    );
  }
}

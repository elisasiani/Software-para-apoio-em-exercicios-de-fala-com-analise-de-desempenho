import 'package:flutter/foundation.dart';

class UserProgress extends ChangeNotifier {
  UserProgress({DateTime Function()? nowProvider})
    : _nowProvider = nowProvider ?? DateTime.now;

  final DateTime Function() _nowProvider;

  String _userName = ''; // Adicionado campo para nome do usuário
  int _streakDays = 0;
  int _totalStars = 0;

  // Chave: id da trilha | Valor: quantidade de exercicios concluidos.
  final Map<String, int> _trilhaProgress = {
    'fonemas': 0,
    'trava_linguas': 0,
  };

  // Guarda os dias em que o usuario concluiu pelo menos um exercicio.
  final Set<String> _diasComExercicio = <String>{};

  String get userName => _userName; // Getter para o nome do usuário

  int get streakDays => _streakDays;
  int get totalStars => _totalStars;

  int getProgressoTrilha(String trilhaId) {
    return _trilhaProgress[trilhaId] ?? 0;
  }

  void updateUserName(String name) { // Método para atualizar o nome do usuário
    _userName = name;
    notifyListeners();
  }

  bool temAtividadeNaData(DateTime data) {
    return _diasComExercicio.contains(_dateKey(data));
  }

  List<bool> getAtividadeSemanaAtual({DateTime? referenceDate}) {
    final inicio = _inicioDaSemana(_normalizarData(referenceDate ?? _nowProvider()));
    return List<bool>.generate(
      7,
      (index) => temAtividadeNaData(inicio.add(Duration(days: index))),
    );
  }

  void completarExercicio(String trilhaId) {
    final progressoAtual = _trilhaProgress[trilhaId] ?? 0;
    if (progressoAtual < 5) {
      _trilhaProgress[trilhaId] = progressoAtual + 1;
    }

    _registrarAtividade(_nowProvider());
    _totalStars += 10;
    notifyListeners();
  }

  void registrarEntradaDiaria() {
    _registrarAtividade(_nowProvider());
    notifyListeners();
  }

  @visibleForTesting
  void registrarAtividadeParaTeste(DateTime data) {
    _registrarAtividade(data);
    notifyListeners();
  }

  void _registrarAtividade(DateTime data) {
    _diasComExercicio.add(_dateKey(data));
    _streakDays = _calcularSequenciaAtual(_normalizarData(data));
  }

  int _calcularSequenciaAtual(DateTime referencia) {
    var total = 0;
    var cursor = referencia;

    while (temAtividadeNaData(cursor)) {
      total++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return total;
  }

  DateTime _inicioDaSemana(DateTime data) {
    final diasDesdeDomingo = data.weekday % DateTime.daysPerWeek;
    return data.subtract(Duration(days: diasDesdeDomingo));
  }

  DateTime _normalizarData(DateTime data) {
    return DateTime(data.year, data.month, data.day);
  }

  String _dateKey(DateTime data) {
    final normalizada = _normalizarData(data);
    final ano = normalizada.year.toString().padLeft(4, '0');
    final mes = normalizada.month.toString().padLeft(2, '0');
    final dia = normalizada.day.toString().padLeft(2, '0');
    return '$ano-$mes-$dia';
  }
}

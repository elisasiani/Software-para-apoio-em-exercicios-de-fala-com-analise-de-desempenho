import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_software_para_apoio_em_exercicios_de_fala_com_analise_de_desempenho/models/user_progress.dart';

void main() {
  test('marca os dias da semana atual a partir do domingo', () {
    final referencia = DateTime(2026, 4, 28);
    final progresso = UserProgress(nowProvider: () => referencia);

    progresso.registrarAtividadeParaTeste(DateTime(2026, 4, 26));
    progresso.registrarAtividadeParaTeste(DateTime(2026, 4, 27));
    progresso.registrarAtividadeParaTeste(DateTime(2026, 4, 28));

    expect(progresso.streakDays, 3);
    expect(
      progresso.getAtividadeSemanaAtual(referenceDate: referencia),
      <bool>[true, true, true, false, false, false, false],
    );
  });

  test('completar exercicio atualiza trilha, estrelas e apenas o dia atual', () {
    final referencia = DateTime(2026, 4, 29);
    final progresso = UserProgress(nowProvider: () => referencia);

    progresso.completarExercicio('fonemas');
    progresso.completarExercicio('fonemas');

    expect(progresso.getProgressoTrilha('fonemas'), 2);
    expect(progresso.totalStars, 20);
    expect(progresso.streakDays, 1);
    expect(
      progresso.getAtividadeSemanaAtual(referenceDate: referencia),
      <bool>[false, false, false, true, false, false, false],
    );
  });
}

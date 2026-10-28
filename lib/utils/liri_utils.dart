// =============================================================
// liri_utils.dart  (colocar em lib/utils/)
// Constantes e funções compartilhadas entre Home, Exercício e
// Relatórios, para que as três telas usem a MESMA regra.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Máximo de tentativas por exercício prescrito.
const int kLimiteTentativas = 3;

/// Login amigável de quem está logado ("joao.123"), sem o "@liri.app".
String loginAtual() {
  const sufixo = '@liri.app';
  final email = FirebaseAuth.instance.currentUser?.email ?? '';
  return email.endsWith(sufixo)
      ? email.substring(0, email.length - sufixo.length)
      : email;
}

/// Mesma data, às 00:00.
DateTime soDia(DateTime d) => DateTime(d.year, d.month, d.day);

/// Domingo (00:00) da semana de [ref]. A semana vai de domingo a sábado.
DateTime inicioDaSemana(DateTime ref) {
  final dia = soDia(ref);
  return DateTime(dia.year, dia.month, dia.day - (dia.weekday % 7));
}

/// Converte os campos `concluido_em` em um conjunto de dias (sem hora)
/// em que houve pelo menos um exercício.
Set<DateTime> diasPraticados(Iterable<Object?> timestamps) {
  final dias = <DateTime>{};
  for (final ts in timestamps) {
    if (ts is Timestamp) dias.add(soDia(ts.toDate()));
  }
  return dias;
}

/// Sequência = dias seguidos praticados, atravessando semanas.
/// Se hoje ainda não praticou, conta a partir de ontem (a sequência
/// só zera quando um dia inteiro passa sem exercício).
int calcularSequencia(Set<DateTime> dias, {DateTime? hoje}) {
  var dia = soDia(hoje ?? DateTime.now());
  if (!dias.contains(dia)) {
    dia = DateTime(dia.year, dia.month, dia.day - 1);
  }
  var seq = 0;
  while (dias.contains(dia)) {
    seq++;
    dia = DateTime(dia.year, dia.month, dia.day - 1);
  }
  return seq;
}

/// Dias da SEMANA ATUAL praticados (0 = domingo … 6 = sábado).
Set<int> diasDaSemanaAtual(Set<DateTime> dias, {DateTime? hoje}) {
  final inicio = inicioDaSemana(hoje ?? DateTime.now());
  final fim = DateTime(inicio.year, inicio.month, inicio.day + 7);
  return {
    for (final d in dias)
      if (!d.isBefore(inicio) && d.isBefore(fim)) d.weekday % 7,
  };
}

// Arquivo: test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// IMPORTANTE: Verifique se o nome do pacote (tcc_software_...) está igual ao seu pubspec.yaml
import 'package:tcc_software_para_apoio_em_exercicios_de_fala_com_analise_de_desempenho/main.dart';

void main() {
  testWidgets('Teste de fumaça do contador', (WidgetTester tester) async {
    // Constrói o app e dispara um frame.
    // Alterado de MyApp para FonoApp para corresponder ao seu código real.
    await tester.pumpWidget(const FonoApp());

    // Verifica se o nosso contador começa em 0.
    // Nota: Se a sua tela inicial mudou e não tem mais o contador padrão, 
    // estas linhas abaixo podem falhar no teste, mas o código em si estará correto.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Toca no ícone '+' e dispara um frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verifica se o nosso contador foi incrementado.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
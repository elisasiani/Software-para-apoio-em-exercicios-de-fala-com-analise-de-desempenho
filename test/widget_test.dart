import 'package:flutter_test/flutter_test.dart';

import 'package:tcc_software_para_apoio_em_exercicios_de_fala_com_analise_de_desempenho/main.dart';

void main() {
  testWidgets('exibe a tela inicial inspirada no Figma', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FonoApp());

    expect(find.text('Bem vindo!'), findsOneWidget);
    expect(find.text('Cadastre-se'), findsOneWidget);
    expect(find.text('Acesse'), findsOneWidget);
  });
}

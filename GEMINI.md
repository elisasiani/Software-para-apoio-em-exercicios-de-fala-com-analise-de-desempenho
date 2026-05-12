# GEMINI.md - Diretrizes do Projeto

## Visão Geral do Projeto
Este projeto é um aplicativo **Flutter (Dart)** desenvolvido como um software de apoio para exercícios de fala, incluindo análise de desempenho. O objetivo é fornecer uma interface lúdica e funcional para crianças e fonoaudiólogos.

### Arquitetura e Tecnologias
- **Framework:** Flutter (Material 3).
- **Gerenciamento de Estado:** `Provider` para persistência e compartilhamento do progresso do usuário (`UserProgress`).
- **Arquitetura de UI:** Baseada em `Screens` e `Widgets` reutilizáveis.
- **Tipografia:** Fonte global **LeagueSpartan**, configurada no `pubspec.yaml` e aplicada via `AppTheme`.
- **Navegação:** Navigator nativo (Imperativo).

## Estrutura de Diretórios
- `lib/models/`: Modelos de dados (`Exercicio`, `UserProgress`).
- `lib/screens/`: Telas principais do fluxo do usuário.
- `lib/theme/`: Configurações centralizadas de cores e estilos (`AppTheme`).
- `lib/widgets/`: Componentes de interface reutilizáveis (`MascoteWidget`, `TrilhaNodeWidget`).
- `assets/`: Recursos estáticos (imagens, fontes e ícones).

## Comandos de Desenvolvimento
- **Instalar Dependências:** `flutter pub get`
- **Executar o Projeto:** `flutter run`
- **Executar Testes:** `flutter test`
- **Limpar Build:** `flutter clean`

## Convenções de Desenvolvimento
- **Clean Code:** Manter lógica de negócio separada da UI. Widgets devem ser decompostos em métodos privados ou novos arquivos se ficarem muito grandes.
- **Tema Centralizado:** Todas as cores e estilos de texto devem, preferencialmente, ser consumidos do `AppTheme` ou definidos em classes de estilo específicas dentro dos arquivos de tela (ex: `_AccessStyles`).
- **Nomenclatura:** Seguir o padrão de estilo oficial do Dart (`PascalCase` para classes, `camelCase` para variáveis e métodos, `snake_case` para nomes de arquivos).
- **Consistência Visual:** Sempre utilizar a fonte `LeagueSpartan` e respeitar a paleta de cores (Roxos, Pêssego/Laranja e tons pastéis).

## Notas Importantes
- A tela `register_screen.dart` foi removida. O fluxo de acesso agora é direto pela `access_screen.dart`.
- O progresso do usuário é gerenciado pelo `UserProgress` através do `ChangeNotifierProvider` no `main.dart`.

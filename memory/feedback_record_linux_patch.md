---
name: feedback-record-linux-patch
description: record_linux 0.7.2 é incompatível com record_platform_interface 1.6.0 — solução é um patch local em packages/record_linux
metadata:
  type: feedback
---

O pacote `record: ^5.1.2` resolve para `record 5.2.1` que puxa `record_platform_interface 1.6.0`. Essa versão adicionou `startStream()` como método abstrato obrigatório e mudou a assinatura de `hasPermission` para incluir `{bool request = true}`. O `record_linux 0.7.2` não implementa esses, causando erro de compilação mesmo ao buildar para Android.

**Why:** Dart compila todos os packages independente da plataforma alvo.

**How to apply:** Manter o diretório `packages/record_linux/` com o patch e o `dependency_overrides` no pubspec.yaml. Não remover — sem isso o build quebra.

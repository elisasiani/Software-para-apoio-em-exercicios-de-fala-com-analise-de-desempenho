# Como gerenciar assinaturas — Guia do administrador

Este guia explica como **VOCÊ** (administrador do Liri) ativa, renova ou
suspende a assinatura de um profissional manualmente, via Firebase Console.

> Quando integrar com um gateway de pagamento (Stripe, Mercado Pago), essas
> operações serão automáticas. Por enquanto, é manual.

---

## Estrutura do documento `profissionais/{uid}`

Cada profissional tem os seguintes campos relacionados à assinatura:

| Campo | Valores possíveis | Significado |
|---|---|---|
| `status` | `"pendente"`, `"ativo"`, `"inativo"` | Estado atual |
| `plano` | `"mensal"`, `"anual"` | Tipo de plano contratado |
| `assinatura_ate` | Timestamp | Quando vence (vazio se nunca ativou) |
| `pagamento_observacao` | string livre | Notas internas |

### O que cada `status` faz

- **`pendente`** — Novos cadastros entram assim. Não acessa o sistema.
- **`ativo`** — Acessa tudo, desde que `assinatura_ate > hoje`.
- **`inativo`** — Bloqueado manualmente (ex: por inadimplência, fraude, etc.)

---

## Fluxo: ativar uma nova conta

Profissional acabou de se cadastrar e pagou? Faça assim:

1. Acesse: https://console.firebase.google.com/project/app-fonoaudiologia-gamificado/firestore/data
2. Abra a coleção `profissionais`
3. Encontre o doc da pessoa (pesquise pelo CPF ou e-mail)
4. Edite os campos:
   - `status` → `ativo`
   - `assinatura_ate` → **data daqui a 30 dias** (clique no tipo "timestamp" e selecione a data/hora)
   - `pagamento_observacao` → "Pago via PIX em DD/MM/AAAA — recibo XXXXX"

✅ Pronto. Na próxima vez que ela fizer login, vai cair direto no dashboard.

---

## Fluxo: renovar mensalidade

Profissional pagou o próximo mês? Faça assim:

1. Mesma navegação do passo anterior
2. **Apenas** atualize `assinatura_ate` para **+30 dias da data atual**
3. (Opcional) Adicione observação: "Renovação MM/AAAA — recibo XXXXX"

> Dica: você pode renovar **antecipadamente** se a pessoa paga adiantado.
> Basta somar 30 dias da data atual de validade.

---

## Fluxo: suspender por inadimplência

Profissional não pagou e quer suspender? Faça assim:

**Opção A** (mais "amigável") — deixa vencer:
- Não faz nada. Quando `assinatura_ate` for menor que hoje, o sistema
  já bloqueia automaticamente.

**Opção B** (imediato) — bloqueia agora:
- Edita o doc, mude `status` para `"inativo"`.
- Na próxima carga de página, é redirecionado pra tela de assinatura.

> Pra **reativar**, basta voltar `status` para `"ativo"` + ajustar a data.

---

## Fluxo: reembolso/cancelamento total

Profissional cancelou? Faça assim:

1. Edite o doc
2. `status` → `inativo`
3. `pagamento_observacao` → "Cancelado em DD/MM/AAAA"

> Não apague o doc imediatamente! Mantenha por uns 30 dias caso a pessoa
> volte atrás. Depois disso, pode apagar (mas isso vai apagar também o
> histórico de pacientes dela do banco).

---

## Avisos automáticos no sistema

- **Faltam ≤ 7 dias para vencer:** banner amarelo no topo do dashboard
- **Vencido:** redireciona pra `assinatura-vencida.html` com botão de WhatsApp
- **Status = `pendente`:** mesma tela, mas com texto "Aguardando ativação"
- **Status = `inativo`:** mesma tela, mas com texto "Conta inativa"

---

## Configurar seu WhatsApp

Edite o arquivo `assinatura-vencida.html` e o `dashboard.js` e troque
o número `5511999999999` pelo seu WhatsApp real (formato internacional,
sem espaços, parênteses ou traços).

Exemplo: para `(11) 98765-4321` use `5511987654321`.

---

## Onde está enforçada a segurança

A verificação acontece em **duas camadas**:

1. **Cliente (JavaScript)** — `assinatura-guard.js`:
   - Em cada página protegida, verifica antes de carregar
   - Redireciona se status != ativo ou se venceu
   - **Pode ser burlado** se alguém mexer no DevTools

2. **Servidor (Firestore Rules)** — `firestore.rules`:
   - Função `profissionalAtivo()` checa status + validade
   - Aplicada em todas as operações de `pacientes/`, `prescricoes/`
   - **Não pode ser burlada** — Firebase enforça isso

Por isso, mesmo que alguém tente acessar pelo URL diretamente, o Firestore
não vai retornar os dados.

---

## Próximos passos (quando virar negócio de verdade)

1. **Integrar Stripe/Mercado Pago** — automatiza o pagamento
2. **Cloud Function de webhook** — atualiza `status` quando pagamento confirma
3. **Cloud Function diária** — verifica `assinatura_ate` e marca vencidos
4. **E-mail de aviso** — notifica 7/3/1 dia antes de vencer

Mas pra MVP/TCC, o sistema atual já é completo e funcional.

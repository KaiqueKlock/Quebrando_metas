# Quebrando Metas

Aplicativo Flutter para transformar metas grandes em acoes menores, com acompanhamento diario de progresso, consistencia e foco.

## Visao Geral

O app foi desenhado para manter execucao simples no dia a dia:

- o usuario cria metas;
- divide cada meta em acoes;
- acompanha progresso por listas, visao semanal e visao mensal;
- escolhe entre modo foco (com timer) ou modo checklist.

## Funcionalidades Atuais

- Criacao, edicao e exclusao de metas.
- Criacao, edicao e exclusao de acoes por meta.
- Priorizacao de metas (ate 3) para a secao "Continue de onde parou".
- Modo Foco com sessao temporizada e regras de contabilizacao.
- Modo Checklist com conclusao por swipe.
- Streak atual e melhor streak.
- Onboarding com captura de nome e saudacao personalizada.
- Tema claro/escuro e cor primaria configuravel.
- Persistencia local dos dados.

## Stack Tecnologica

- Flutter
- Dart
- Riverpod
- GoRouter
- Hive
- flutter_test

## Estrutura Principal

```text
lib/
  app/
  core/
  features/
    dashboard/
    goals/
    onboarding/
```

## Decisoes Tecnicas e Testes

### Decisoes tecnicas principais

- Navegacao por `goalId` em path params (sem depender de `state.extra`).
- Persistencia local em Hive com mapeadores tipados.
- Home unificada na rota principal, com compatibilidade de rota legada.
- Regra de prioridades com limite de 0..3 metas ativas.
- "Proxima acao" do destaque definida por menor `totalFocusMinutes` (desempate por `order`).
- Modo foco em tela dedicada, com timer baseado em relogio real.
- Regras de foco:
  - `Concluir agora` habilita apenas com `>= 5 min`;
  - `Cancelar` soma tempo apenas com `>= 1 min`.
- Modo checklist:
  - conclusao por swipe;
  - sem fluxo de foco na exibicao das acoes.
- Onboarding controlado por estado persistido e redirect no router.

### Cobertura de testes

- Unit tests para regras de dominio (streak, foco, status diario, mapeadores).
- Widget tests para fluxos principais e comportamento visual.
- Golden tests (quando habilitados) para regressao visual de telas-chave.

### Perfis de execucao (Windows)

Script oficial: `scripts/run_tests.ps1`

Perfis:

- `smoke`: validacao rapida das regras centrais.
- `regression`: smoke + onboarding + persistencia + compatibilidade.
- `full`: suite completa.

Exemplos:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile smoke -Expanded
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile regression -Expanded
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile full -Expanded
```

Modo recomendado para ambiente Windows mais instavel:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile smoke -Expanded -TimeoutSeconds 420 -KeepGoing
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile regression -Expanded -TimeoutSeconds 420 -KeepGoing
```

Flags uteis:

- `-TimeoutSeconds <n>`
- `-KeepGoing`
- `-IncludeQuarantine`
- `-ClearFlutterLocks`
- `-Clean`
- `-PubGet`

## Como Executar

```bash
flutter pub get
flutter run
```

## Autor

Kaique Klock

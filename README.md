# Quebrando Metas

Quebrando Metas é um aplicativo mobile desenvolvido em Flutter que ajuda pessoas a transformar objetivos grandes em pequenas ações executáveis.

A proposta do aplicativo é tornar o progresso visível e ajudar o usuário a manter clareza sobre qual é o próximo passo para alcançar uma meta.

Em vez de lidar com objetivos abstratos, o usuário divide suas metas em pequenas ações e acompanha sua evolução ao longo do tempo.

---

# Ideia do Projeto

Muitas pessoas definem metas importantes como:

- emagrecer
- aprender um novo idioma
- estudar programação
- melhorar hábitos

No entanto, essas metas frequentemente acabam sendo abandonadas.

Um dos principais motivos é que objetivos grandes costumam ser difíceis de executar no dia a dia. Quando uma meta não possui ações claras e mensuráveis, o progresso se torna invisível e a motivação diminui.

O aplicativo **Quebrando Metas** foi criado para resolver esse problema.

A proposta é permitir que qualquer meta seja dividida em pequenas ações que podem ser executadas individualmente, facilitando a construção de progresso ao longo do tempo.

---

# Exemplo de Uso

**Meta**
Emagrecer

**Ações da meta**
- Treinar 3 vezes por semana
- Melhorar alimentação
- Dormir melhor
- Reduzir açúcar

À medida que as ações são concluídas, o aplicativo calcula automaticamente o progresso da meta.

**Exemplo de progresso**

4 ações
2 concluídas
Progresso: 50%

Essa visualização simples ajuda o usuário a perceber evolução e manter consistência.

---

# Objetivo do Projeto

Este projeto foi desenvolvido com dois objetivos principais:

- Explorar a construção de um aplicativo de produtividade simples e orientado a ações
- Evoluir habilidades práticas em desenvolvimento mobile utilizando Flutter

O projeto segue a filosofia de **aprender através da construção**, buscando desenvolver um produto funcional enquanto práticas de arquitetura e organização de código são aplicadas progressivamente.

---

# Funcionalidades do MVP

O MVP do aplicativo inclui as seguintes funcionalidades:

- Criar uma nova meta
- Editar metas existentes
- Excluir metas
- Adicionar ações dentro de uma meta
- Editar ações
- Excluir ações
- Marcar ações como concluídas
- Visualizar progresso da meta
- Visualizar lista de metas ativas

O aplicativo funciona inicialmente de forma **local-first**, sem backend ou sincronização em nuvem.

---

### Modo Foco (Sprint 5 - Entregue)

O fluxo de Modo Foco foi implementado e esta integrado na tela de acoes da meta.

## Objetivo

Registrar tempo real investido em cada acao e refletir isso em progresso de consistencia (streak) e metricas de tempo.

## Fluxo atual

1. Usuario seleciona uma acao pendente.
2. Toca em `Iniciar foco`.
3. Escolhe a duracao (`15`, `30` ou `60` minutos) em bottom sheet.
4. App abre uma page dedicada de foco com:
- titulo da acao e nome da meta
- contador regressivo `mm:ss`
- progresso circular regressivo (de 100% para 0%)
- botoes `Cancelar` e `Concluir agora`
5. Ao concluir:
- sessao e registrada como `completed`
- minutos reais decorridos sao acumulados na acao/meta
- acao **nao** e concluida automaticamente
6. Ao cancelar:
- sessao e registrada como `canceled`
- soma minutos apenas com `>= 1 min`
- com `< 1 min`, nao soma tempo

## Regras oficiais

- Streak conta somente quando usuario inicia foco.
- Conclusao manual da acao nao incrementa streak.
- Quebra de 1 dia sem inicio de foco zera streak atual.
- `Concluir agora` habilita somente apos `>= 5` minutos decorridos.
- Navegacao de retorno/gesture e bloqueada durante foco ativo; saida apenas por `Cancelar` ou `Fechar`.

---

### Sprint 6 - UI/UX Definitiva (Em andamento)

Resumo do estado atual (atualizado em 20/03/2026).

## Etapas concluidas

1. Etapa 6.1 - Consolidacao da navegacao principal
- [x] App voltou para 1 experiencia principal.
- [x] Compatibilidade mantida com `/` e `/goals` (mesmo layout da home).
- [x] FAB de criacao preservado.

2. Etapa 6.2 - Refactor visual da Home
- [x] Header centralizado com `Ola!`, streak e horas investidas.
- [x] Card `CONTINUE DE ONDE PAROU` com ate 3 metas prioritarias.
- [x] Regra de `Proxima acao` baseada em menor `totalFocusMinutes` (desempate por `order`).
- [x] Secao `Suas Metas` compacta, limpa e com progresso linear.

3. Etapa 6.3 - Refactor visual do detalhe da meta
- [x] Layout sem `Etapas`.
- [x] Descricao da meta acima do bloco de progresso linear.
- [x] FAB de nova acao em icone-only.
- [x] Lista direta de acoes com foco no fluxo de execucao.

4. Etapa 6.4 - Responsividade e robustez
- [x] Ajustes para telas pequenas e cenarios de overflow.
- [x] Cobertura para overflow no fluxo de foco e conclusao de foco.

5. Etapa 6.5 - Testes e cobertura visual
- [x] Widget tests readaptados para nova UI.
- [x] Finders/keys atualizados para foco, prioridade e navegacao.
- [x] Golden tests ativos:
  - `test/goldens/dashboard_home_sprint6.png`
  - `test/goldens/goal_detail_sprint6.png`

6. Etapa 6.6 - Fechamento documental
- [x] `Project.md` e `README.md` sincronizados com regras e estado atual.

## Pendencias abertas

1. Revisao visual final em breakpoints extremos (muito pequeno e tablet).

---

### Sprint 7 - Onboarding (Concluido em 26/03/2026)

Resumo do que foi entregue no onboarding:

- Fluxo inicial funcional com captura de nome.
- Redirect seguro no router:
  - onboarding pendente -> `/onboarding`;
  - onboarding concluido -> `/`.
- Cold start ajustado: sem flag salva, o app considera onboarding pendente.
- Onboarding com UX refinada:
  - copy curta e objetiva,
  - botao principal com estados (`desabilitado`/`loading`),
  - layout resiliente para rotacao e tela pequena.
- Saudacao personalizada na Home:
  - `Olá, Nome!` com variacao ocasional (`Olá`, `Oi`, `Bem vindo de volta`, `Eai`).
- Testes de onboarding adicionados em:
  - `test/features/onboarding/presentation/onboarding_flow_test.dart`

---


# Stack Tecnologica

O projeto foi desenvolvido utilizando:

- Flutter
- Dart
- Riverpod (gerenciamento de estado)
- GoRouter (navegação)
- Hive ou Isar (persistência local)
- flutter_test
- integration_test

---

## Estrutura principal

```text
lib/
  app/
    app.dart
    router.dart

  core/
    constants/
    errors/
    utils/
    widgets/

  features/
    goals/
      data/
      domain/
      presentation/

    dashboard/
      presentation/

    onboarding/
      presentation/
``` 
---

# Arquitetura e Princípios

O projeto segue alguns princípios principais.

### Simplicidade

O MVP prioriza clareza e simplicidade, evitando abstrações desnecessárias.

### Separação de responsabilidades

Lógica de negócio não deve estar diretamente nos widgets.

### Feature-first

A organização do projeto é orientada por funcionalidades em vez de camadas globais.

### Componentização

A interface é construída utilizando widgets pequenos e reutilizáveis.

---
# Decisoes Tecnicas

Decisoes atuais de arquitetura e implementacao (alinhadas ao `Project.md`):

- Navegacao de metas e acoes por `goalId` em path params, sem dependencia de `state.extra`.
- Onboarding persistido localmente em Hive e aplicado no redirect do GoRouter (`refreshListenable`).
- Cold start de onboarding: sem valor salvo de conclusao, onboarding inicia como pendente.
- Persistencia local em Hive com mappers tipados (`Map<String, dynamic>`), incluindo metas, acoes, sessoes de foco e estatisticas de streak.
- Home unificada: rota `/goals` mantida por compatibilidade, reutilizando `DashboardPage`.
- Prioridades de metas com regra 0..3:
  - apenas metas ativas podem ser priorizadas;
  - normalizacao automatica de ranking;
  - card `Continue de onde parou` exibe ate 3 prioridades.
- Regra da `Proxima acao` no card de destaque:
  - acao pendente com menor `totalFocusMinutes`;
  - em empate, menor `order`.
- Modo foco em page dedicada:
  - duracoes `15/30/60`;
  - timer por relogio real (recalcula ao voltar de background);
  - bloqueio de saida via back/gesture durante sessao ativa.
- Regras finais do foco:
  - `Concluir agora` habilita apos `>= 5 min`;
  - `Cancelar` acumula apenas com `>= 1 min`;
  - concluir foco nao conclui acao automaticamente.
- Conclusao manual de acao por `swipe`, bloqueada sem foco registrado (`Sem tempo gasto na acao.`).
- Tema com Drawer de aparencia:
  - alternancia claro/escuro por icone unico;
  - selecao de cor principal com filtro WCAG.
- Estrategia de testes combinando unit, widget e golden tests para cobertura de regra e regressao visual.

---
# Testes

O projeto utiliza três níveis de testes.

### Unit Tests

Validação de regras de negócio, como cálculo de progresso das metas.

### Widget Tests

Testes de interface e renderização de componentes.

### Integration Tests

Validação do fluxo principal do usuário.

Fluxo mínimo testado:

- Criar meta
- Adicionar ações
- Concluir ação
- Ver progresso atualizado

---

# Evoluções Futuras

Possíveis evoluções após o MVP:

- Sincronização em nuvem
- Conta de usuário
- Metas compartilhadas
- Gamificação
- Sugestões inteligentes de ações
- Análise de hábitos

---

# Filosofia do Projeto

O desenvolvimento do aplicativo segue três ideias principais.

### Entregar valor rapidamente

Pequenas funcionalidades completas são priorizadas em vez de grandes implementações complexas.

### Simplicidade acima de complexidade

O foco do MVP é resolver o problema central com o menor nível de complexidade possível.

### Aprender construindo

O projeto também funciona como um laboratório de aprendizado prático em desenvolvimento mobile.

---

# Autor

Projeto desenvolvido por **Kaique Klock**







## Perfis de execucao de testes (Windows)

Para reduzir travamentos/intermitencias e acelerar o fluxo diario, foi adicionado um runner com preflight:

- Script: `scripts/run_tests.ps1`
- Preflight automatico:
  - encerra processos `flutter/dart` pendurados;
  - ajusta PATH para priorizar `Git for Windows` quando disponivel;
  - preserva lockfiles do SDK por padrao (evita conflito com analysis server do IDE);
  - limpa artefatos de teste em `build/unit_test_assets` e `build/native_assets`.
- O runner executa `flutter test` com:
  - `--concurrency=1`;
  - `--suppress-analytics` (padrao, para reduzir lock/telemetry no Windows);
  - timeout de teste do Flutter (`--timeout`, configuravel).

Perfis disponiveis:

- `smoke`: validacao rapida de dominio (estavel).
- `regression`: `smoke` + onboarding + compatibilidade de mappers + persistencia de streak.
- `full`: todos os arquivos de teste (inclui golden e widget suite).

Obs: por padrao, o runner em modo por arquivos nao executa apenas a quarentena de contraste/WCAG. Use `-IncludeQuarantine` para inclui-la.

Exemplos de uso:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile smoke -Expanded
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile regression -Expanded
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile full -Expanded
```

### Modo anti-trava (recomendado no Windows)

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile smoke -Expanded -TimeoutSeconds 420 -KeepGoing
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile regression -Expanded -TimeoutSeconds 420 -KeepGoing
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile full -Expanded -TimeoutSeconds 420 -KeepGoing
```

Flags uteis:

- `-TimeoutSeconds <n>`: define `--timeout` do `flutter test` (ex.: `420s`).
- `-KeepGoing`: continua executando os proximos alvos e gera resumo final de falhas.
- `-Clean`: executa `flutter clean` no preflight.
- `-PubGet`: executa `flutter pub get` no preflight.
- `-IncludeQuarantine`: inclui testes marcados como instaveis (podem voltar a travar no Windows).
- `-ClearFlutterLocks`: tenta remover lockfiles do SDK Flutter no preflight (use apenas se realmente precisar).
- `-SkipPreflight`: ignora limpeza inicial.
- `-NoSuppressAnalytics`: desativa `--suppress-analytics` (nao recomendado no Windows).

### Execucao por tags (CI)

Tambem e possivel executar por tags reais do `flutter test`:

```powershell
flutter test --tags smoke -r expanded --concurrency=1
flutter test --tags regression -r expanded --concurrency=1
flutter test --tags full -r expanded --concurrency=1
```

No runner em `scripts/run_tests.ps1`, use `-UseTags` para aplicar o mesmo fluxo:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile smoke -UseTags -Expanded
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile regression -UseTags -Expanded
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile full -UseTags -Expanded
```

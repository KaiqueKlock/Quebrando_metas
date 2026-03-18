# PROJECT.md - Quebrando Metas

## 1. Visão do Produto

**Quebrando Metas** é um aplicativo mobile que ajuda o usuário a transformar objetivos grandes em pequenas ações executáveis, permitindo visualizar progresso e manter clareza sobre o próximo passo.

O objetivo central é reduzir a sensação de sobrecarga causada por metas grandes e abstratas, tornando o progresso visível, simples e motivador.

### Exemplo de Uso

**Meta:**  
Emagrecer

**Ações:**
- Treinar 3 vezes por semana
- Melhorar alimentação
- Dormir melhor
- Reduzir açúcar

O usuário pode acompanhar o progresso de cada meta conforme conclui suas ações.

## 2. Problema que o App Resolve

Muitas pessoas:
- Definem metas grandes
- Não sabem por onde começar
- Perdem motivação ao longo do caminho

Isso acontece porque:
- Metas são abstratas
- Não existe divisão clara em pequenas ações
- Progresso não é visível

O app resolve isso ao permitir:
- Quebrar metas em ações pequenas
- Visualizar progresso
- Manter foco na próxima ação

## 3. Público-alvo (MVP)

Usuários que:
- Querem organizar objetivos pessoais
- Buscam melhorar hábitos
- Gostam de ferramentas simples de produtividade

### Exemplos
- Quem quer emagrecer
- Quem quer estudar algo novo
- Quem quer organizar projetos pessoais
- Quem quer melhorar hábitos

## 4. Escopo do MVP

O MVP será **local-first**, sem backend.

### Funcionalidades do MVP

Usuário pode:
- Criar uma meta
- Editar uma meta
- Excluir uma meta
- Adicionar ações à meta
- Editar ações
- Excluir ações
- Marcar ações como concluídas
- Visualizar progresso da meta
- Ver lista de metas ativas

## 5. Fora do Escopo do MVP

Estas funcionalidades não fazem parte do MVP:
- Login
- Sincronização em nuvem
- Gamificação
- Ranking
- Compartilhamento social
- Notificações inteligentes
- Sugestão automática de ações com IA

Essas ideias ficam para versões futuras.

## 6. Stack Tecnológica

Este projeto utiliza:
- Flutter
- Dart
- Riverpod (gerenciamento de estado)
- GoRouter (navegação)
- Hive ou Isar (persistência local)
- `flutter_test`
- `integration_test`

## 7. Estrutura do Projeto

A estrutura segue organização por features.

```text
lib/
  app/
    app.dart
    router.dart
    theme/
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
test/
integration_test/
```

Cada feature pode conter:
- `data`
- `domain`
- `presentation`

Mas abstrações desnecessárias devem ser evitadas no MVP.

## 8. Modelo de Dados (MVP)

### Goal (Meta)

Campos:
- `id`
- `title`
- `description`
- `createdAt`
- `updatedAt`
- `completedActions`
- `totalActions`
- `progress` (derivado)

### Action (Ação)

Campos:
- `id`
- `goalId`
- `title`
- `isCompleted`
- `createdAt`
- `updatedAt`
- `order`
- `completedAt` (opcional)

### Regra de Progresso

Progresso da meta (derivado):

```text
progress = acoes_concluidas / total_de_acoes
```

Exemplo:
- 4 ações
- 2 concluídas
- Progresso = 50%

## 9. Fluxo Principal do Usuário

Fluxo básico do app:
1. Usuário abre o app
2. Visualiza lista de metas
3. Cria uma nova meta
4. Adiciona ações
5. Marca ações como concluídas
6. Visualiza progresso da meta

Esse é o core loop do produto.

### 9.1 Especificação da Home (MVP)

#### Topo
- Saudação curta
- Quantidade de metas ativas
- Progresso médio das metas ativas

Fórmula de progresso médio:

```text
progresso_medio = soma(progress_das_metas) / quantidade_de_metas_ativas
```

Regra para estado vazio:
- Se não houver metas ativas, exibir `0 metas ativas` e `Progresso médio: 0%`

#### Card de destaque: Continue de onde parou
- Exibe meta em andamento
- Exibe progresso da meta
- Exibe próxima ação pendente
- Botão `Continuar`

Regra inicial de seleção da meta destacada:
- Escolher a primeira meta ativa da lista ordenada
- Ordenação padrão da Home:
- Primeiro metas com ações pendentes
- Depois metas com menor progresso
- Em empate, meta mais antiga (`createdAt`)

#### Seção: Suas metas
Cada card de meta deve mostrar:
- Nome da meta
- Barra de progresso
- Percentual
- `x de y ações concluídas`
- Próxima ação pendente

#### Ação principal da tela
- Botão flutuante: `+ Nova Meta`

#### Estados obrigatórios da Home
- `loading`
- `withData`
- `empty`
- `error` (com ação de tentar novamente)

#### Critérios de aceite da Home
- Usuário entende em poucos segundos quantas metas ativas possui
- Usuário visualiza progresso médio e progresso por meta
- Usuário identifica a próxima ação a executar
- Usuário consegue iniciar criação de meta pela ação principal
- Interface mantém linguagem orientada a `ações`, nunca `etapas`

### 9.2 Navegação inicial com GoRouter
- O app usa `MaterialApp.router`
- Rotas base:
- `/` para Dashboard (Home)
- `/onboarding` para Onboarding
- Redirect inicial:
- Se onboarding não concluído, abrir `/onboarding`
- Se onboarding concluído, abrir `/`
- No Sprint 0, a flag de onboarding pode ser mock/local até a persistência ser implementada

## 10. Princípios de Arquitetura

### 1. Simplicidade
Evitar overengineering.

### 2. Separação de responsabilidades
Evitar lógica de negócio dentro de widgets.

### 3. Widgets pequenos
Preferir componentes como:
- `GoalCard`
- `ActionTile`
- `ProgressIndicator`
- `GoalForm`

### 4. Feature-first
Organizar código por feature, não por camada global.

## 11. Regras de Código

Convenções:
- Nomes em inglês
- Variáveis descritivas
- Métodos pequenos
- Evitar widgets muito grandes
- Evitar lógica complexa no `build()`

Exemplo correto:
- `GoalProgressCalculator`
- `GoalRepository`
- `GoalController`

Evitar:
- `UtilsHelperServiceManager`

## 12. Estratégia de Testes

### Unit Tests
Testar regras de negócio:
- Cálculo de progresso
- Validação de meta
- Validação de ações

### Widget Tests
Testar interface:
- Renderização da lista
- Formulário de criação
- Barra de progresso

### Integration Tests
Fluxo mínimo:
- Criar meta
- Adicionar ações
- Concluir ação
- Progresso atualizado

## 13. Critérios de Pronto

Uma feature é considerada pronta quando:
- Funciona corretamente
- Não quebra análise estática
- Possui testes adequados
- Segue padrão do projeto
- Não adiciona complexidade desnecessária

## 14. Workflow de Desenvolvimento

Cada feature segue:
1. Definir micro-objetivo
2. Pedir plano para IA
3. Implementar em pequenos blocos
4. Testar
5. Revisar arquitetura
6. Atualizar `PROJECT.md` se necessário
7. Commit pequeno

## 15. Uso da IA no Projeto

A IA atua como par de programação.

Pode ajudar com:
- Boilerplate
- Widgets
- Testes
- Refactors
- Análise de código

Não deve decidir sozinha:
- Arquitetura grande
- Mudanças de stack
- Escopo do produto

## 16. Regras para Interação com IA

Sempre pedir:
- Plano curto
- Arquivos a alterar
- Modelo de dados
- Testes necessários
- Ordem de implementação

Evitar pedidos como:
- "Crie o app inteiro"

Preferir:
- "Vamos implementar a feature X em pequenos passos"

## 17. Estratégia de Branches

Branches principais:
- `main`
- `develop`

Branches de feature:
- `feature/create-goal`
- `feature/goal-actions`
- `feature/goal-progress`

## 18. Convenção de Commits - pode ser em portugues

- `feat: add goal creation flow`
- `feat: implement goal actions`
- `test: add goal progress tests`
- `refactor: simplify goal controller`
- `fix: correct progress calculation`

## 19. Roadmap do MVP

### Sprint 0 - Fundação
- Status: Concluído em 11/03/2026
- Criar projeto ✅
- Configurar estrutura ✅
- Criar `PROJECT.md` ✅
- Configurar router ✅
- Criar home inicial ✅

Entregas registradas:
- Estrutura base `app/core/features` criada
- Navegação inicial com `GoRouter` configurada
- Home MVP inicial implementada (topo, destaque, lista e CTA principal)

### Sprint 1 - Metas
- Status: Concluído em 11/03/2026
- Lista de metas ✅
- Criar meta ✅ (fluxo inicial)
- Editar meta ✅
- Excluir meta ✅ 
- Persistência local ✅ (metas com Hive)

### Sprint 2 - Ações
- Status: Concluído em 11/03/2026
- Adicionar ações ✅
- Listar ações ✅
- Editar ações ✅
- Excluir ações ✅


### Sprint 3 - Progresso
- Status: Concluído em 12/03/2026
- Concluir ações ✅
- Calcular progresso ✅
- Exibir progresso ✅
- Metas -> retorno da tela de meta sem estado "Tentar novamente" ✅ (teste com 10 ciclos de ida e volta)
- Ações e Metas -> input extremo tratado com `inputFormatter` + `validator` + feedback visual ✅

### Sprint 4 - Polimento
- Status: Concluido em 18/03/2026

- Melhorar UX
  - [x] Separacao em abas (Dashboard / Suas Metas)
  - [x] Metas prioritarias (0 a 3)
  - [x] Mensagem amigavel para estado sem prioridade: `Defina uma meta como prioridade.`

- Trazer novos cenarios para testes
  - [x] Usuario rotaciona tela ao inserir texto em Title e Description (teclado aberto)
  - [x] Usuario define etapa prioritaria ja existente
  - [x] Usuario conclui meta que estava marcada como prioridade
  - [x] Usuario adiciona acao em meta concluida
  - [x] Usuario rotaciona tela com Drawer aberto sem perder interacao
  - [x] Usuario em tela pequena (altura/largura reduzida) sem overflow de layout ("over pixel")
  - [x] Regressao de prioridades: remover e adicionar metas priorizadas com titulos de tamanhos diferentes sem desalinhamento visual no Dashboard
  - [x] Card de resumo em `Suas Metas` permanece fixo durante o scroll da lista

- Refinar UI
  - [x] Centralizar botao `Nova Meta` no navigator, removendo o texto do botao
  - [x] Padronizar alinhamento a esquerda dos itens do card `Continue de onde parou`, incluindo metas com titulo longo
  - [x] Mover card de resumo para `Suas Metas`, mantendo o Dashboard livre para evolucoes futuras
  - [x] Destacar visualmente o card de resumo (cor, borda e elevacao)
- Refinamento de Theme
  - [x] Adicionar Drawer na AppBar para configuracoes de aparencia (Dashboard e Suas Metas)
  - [x] Adicionar alternancia de tema (`Claro`/`Escuro`) com icone unico (`sol`/`lua`)
  - [x] Adicionar menu recolhivel para escolha de cor principal
  - [x] Persistir preferencias de tema localmente

- Sugestoes de melhoria (proximos passos)
  - [x] Revisar contraste e acessibilidade (WCAG) das cores selecionaveis
  - [x] Refinar espacamento/altura de cards para melhor leitura em telas menores
  - [x] Adicionar micro-animacoes leves na troca de abas e prioridades


### Sprint 5 - Modo Foco (Pomodoro)
- Status: Em andamento (atualizado em 18/03/2026 - etapas 5.1 a 5.4 concluidas, com 1 regra pendente de cancelamento)

Referencia funcional detalhada:
- Ver `README.md` -> `Nova Feature Planejada - Modo Foco (Sprint 5)`

Regra oficial de streak:
- O streak conta somente quando o usuario inicia foco em uma acao.
- Conclusao manual da acao nao incrementa streak.
- Se passar 1 dia sem iniciar foco, streak zera.

Etapas pequenas de implementacao:

1. Etapa 5.1 - Modelo de dados e persistencia
- [x] Criar entidade `FocusSession` (id, actionId, goalId, startedAt, endedAt, durationMinutes, status).
- [x] Adicionar campos de tempo acumulado na acao (`totalFocusMinutes`) e data do ultimo foco.
- [x] Atualizar mappers e repositorio local para salvar os novos campos.

2. Etapa 5.2 - Fluxo de inicio do foco
- [x] Habilitar CTA `Iniciar foco` ao selecionar uma acao.
- [x] Permitir escolher duracao pre-definida (15, 25, 45 minutos).
- [x] Iniciar timer em tela dedicada/modal com estado reativo.

3. Etapa 5.3 - Tela durante foco
- [x] Exibir nome da meta, nome da acao, tempo restante e botao de cancelar.
- [x] Manter experiencia direta, sem exigir navegacao extra.
- [x] Em cancelamento, registrar sessao cancelada sem somar tempo acumulado.

4. Etapa 5.4 - Finalizacao do foco
- [x] Ao concluir timer, registrar sessao concluida e mostra tempo gasto.
- [x] Incrementar automaticamente `totalFocusMinutes` da acao.
- [x] Atualizar agregado de tempo da meta (soma das acoes da meta).
- [x] Nao concluir acao automaticamente.
- [ ] Ao cancelar, o tempo acumulado conta se for a partir de 5 minutos de foco. 

5. Etapa 5.5 - Conclusao manual da acao
- [x] Implementar conclusao manual por gesto (ex: swipe lateral). remover bolinha de seleção e manter a seleção onde hoje é a conclusão da ação. Conclusão passa a ser por swipe lateral.
- [x] Registrar `completedAt` na acao ao concluir.
- [x] Recalcular progresso da meta apos conclusao.

6. Etapa 5.6 - Logica de streak
- [x] Registrar o dia de cada inicio de foco.
- [x] Calcular streak atual por dias consecutivos com pelo menos 1 inicio de foco por dia.
- [x] Resetar streak quando houver quebra de 1 dia sem foco.
- [x] Persistir `bestStreak` para historico.

7. Etapa 5.7 - Exibicao de dados
- [x] Mostrar tempo acumulado por acao.
- [x] Mostrar tempo total acumulado da meta.
- [x] Mostrar streak atual em ponto de destaque de UX (definir local no inicio da etapa).

8. Etapa 5.8 - Testes
- [x] Unit tests para acumulacao de minutos e calculo de streak.
- [x] Widget tests para fluxo iniciar/cancelar/finalizar foco.
- [x] Widget test para conclusao manual de acao sem foco concluido (regra atual: bloquear e mostrar feedback).
- [x] Regressao: foco concluido soma tempo e nao marca acao como concluida automaticamente.

### Sprint 6 - Release MVP
- Testes finais
- Revisão
- Build release
- Roadmap V2

## Decisões técnicas (12/03/2026)

- Navegação de edição/ações de metas refatorada para `goalId` em path params, removendo dependência de `state.extra`.
- Estado de onboarding movido para storage local com Hive + `ChangeNotifier` (`refreshListenable` no `GoRouter`).
- Persistência local tipada com `Map<String, dynamic>` em mappers e repositório.
- Home ajustada para considerar apenas metas ativas no topo e no progresso médio.
- Fluxo de ações estabilizado com atualização explícita da Home após mutações.
- Validação centralizada por `TitleValidator` com limite de caracteres também no input (`LengthLimitingTextInputFormatter`).
- Tratamento de erro de UI padronizado com `SnackBar` em criação/edição de metas e ações.
- Cobertura de testes ampliada para:
- usuário com histórico longo (10 metas concluídas + 5 ativas),
- CRUD de ações,
- input extremo (título e descrição longos),
- estabilidade no retorno da tela de ações (10 ciclos sem estado de retry).

### Atualizacao tecnica (13/03/2026)

- Navegacao principal dividida em duas abas com `NavigationBar` + `GoRouter`:
  - `Dashboard` para resumo e foco no proximo passo.
  - `Suas Metas` para gestao completa das metas.
- A decisao por `NavigationBar + context.go` foi adotada no Sprint 4 para reduzir risco e manter o fluxo principal estavel.
- A secao `Continue de onde parou` passou a priorizar metas escolhidas pelo usuario.
- Modelo `Goal` atualizado com `priorityRank` (1..3), persistido em storage local.
- Regras de prioridade implementadas:
  - limite maximo de 3 metas prioritarias,
  - apenas metas ativas podem ser priorizadas,
  - normalizacao automatica de ranking para evitar inconsistencias.
- Estado com 0 prioridades tratado com mensagem amigavel: `Defina uma meta como prioridade.`
- Cobertura de widget tests ampliada para navegacao por abas e fluxo de metas prioritarias.

### Atualizacao tecnica (17/03/2026)

- Corrigido desalinhamento visual na secao `Continue de onde parou` ao alternar prioridades com titulos de tamanhos diferentes.
- Ajuste de layout aplicado para manter os itens de prioridade com largura consistente e ancoragem a esquerda.
- Adicionado widget test de regressao para o fluxo: priorizar 3 metas, remover 1, adicionar outra e validar alinhamento horizontal dos titulos no Dashboard.
- Validacao executada com suite completa de testes (`flutter test -r compact`) sem falhas.

### Atualizacao tecnica (18/03/2026)

- Sprint 4 concluido oficialmente.
- Card de resumo (`metas concluidas`, `metas ativas`, `progresso medio`) movido para a aba `Suas Metas`.
- Layout da aba `Suas Metas` refatorado para separar header fixo e lista rolavel (`Expanded + ListView`).
- Dashboard mantida sem esse bloco para abrir espaco a implementacoes futuras.
- Adicionado teste para garantir que o card de resumo permanece fixo durante o scroll.
- Validacao executada com suite completa de testes (`flutter test -r compact`) sem falhas.

### Atualizacao tecnica (18/03/2026 - Sprint 5)

- Etapa 5.1 concluida com modelo e persistencia de foco:
  - entidade `FocusSession` adicionada;
  - `ActionItem` com `totalFocusMinutes` e `lastFocusStartedAt`;
  - mappers e repositorio local atualizados para os novos campos.
- Etapa 5.2 concluida com fluxo de inicio de foco:
  - selecao da acao para foco;
  - CTA `Iniciar foco`;
  - escolha de duracao (15, 25, 45);
  - abertura de modal com timer reativo.
- Etapa 5.3 concluida com experiencia durante foco:
  - modal exibe meta, acao e tempo restante;
  - cancelamento registra sessao `canceled` e nao soma tempo.
- Ajuste adicional de regra funcional:
  - bloqueio de conclusao de acao sem foco concluido;
  - feedback amigavel em UI: `Sem tempo gasto na acao.`
- Etapa 5.4 concluida (parcialmente, com 1 regra pendente):
  - ao concluir foco, sessao passa para `completed`;
  - tempo da sessao soma automaticamente em `totalFocusMinutes` da acao;
  - agregado da meta foi adicionado (`Goal.totalFocusMinutes`) e recalculado pela soma das acoes;
  - acao nao e concluida automaticamente apos foco;
  - modal mostra `Tempo gasto: X min` apos concluir com base no tempo realmente decorrido.
- Etapa 5.5 concluida:
  - conclusao manual da acao migrou para gesto de `swipe` lateral;
  - controle de selecao para foco foi reposicionado para a area da antiga conclusao;
  - `completedAt` e recálculo de progresso seguem pelo fluxo de atualizacao da acao;
  - testes de widget atualizados para validar conclusao por `swipe`.
- Etapa 5.6 concluida:
  - streak passa a ser calculada por dias com inicio de foco (`startedAt`);
  - dias consecutivos sao contados por data (ignorando duplicidade de sessoes no mesmo dia);
  - streak zera quando o ultimo inicio de foco estiver ha mais de 1 dia;
  - `bestStreak` persistido em storage local para historico;
  - provider `focusStreakProvider` adicionado para streak atual e `bestFocusStreakProvider` para historico/migracao.
- Regra pendente mantida por decisao de escopo:
  - no cancelamento, acumular tempo somente quando houver 5+ minutos de foco (ainda nao implementado).
- Cobertura de testes ampliada para Sprint 5:
  - fluxo iniciar/cancelar foco;
  - fluxo concluir foco com acumulacao de tempo;
  - regressao para garantir que concluir foco nao conclui acao automaticamente;
  - bloqueio de conclusao manual sem foco registrado;
  - regressao para conclusao antecipada (ex: sessao de 45 min encerrada com 2 min soma 2 min);
  - overflow em tela pequena durante modal de foco.
- Validacao executada com suite completa de testes (`flutter test -r compact`) sem falhas.

### Atualizacao tecnica (18/03/2026 - Sprint 5.6/5.8)

- Persistencia de streak finalizada com `bestStreak` em storage local:
  - `GoalsRepository` expandido com leitura/escrita de melhor sequencia;
  - `LocalGoalsRepository` com box dedicada de estatisticas de foco;
  - `bestFocusStreakProvider` com migracao automatica a partir das sessoes historicas quando necessario.
- Regras de streak fortalecidas com cenarios de borda:
  - sessoes fora de ordem cronologica;
  - duplicidade de inicios no mesmo dia;
  - sequencias atraves de virada de mes;
  - confirmacao de melhor sequencia historica sem regressao.
- Cobertura de testes ampliada para comportamento real do produto:
  - conclusao manual bloqueada sem tempo de foco concluido (`Sem tempo gasto na acao.`);
  - melhor streak nao aumenta com multiplos inicios no mesmo dia;
  - melhor streak persistido nao e sobrescrito por historico inferior;
  - streak atual zera apos quebra de 1 dia sem inicio de foco.
- Validacao executada com suite completa de testes (`flutter test -r compact`) sem falhas.

### Atualizacao tecnica (18/03/2026 - Sprint 5.7)

- Ponto de destaque de streak definido em UX conforme decisao de produto:
  - o card de resumo da aba `Suas Metas` agora exibe `Streak atual` e `Melhor streak` junto de metas ativas/concluidas e progresso medio.
- Exibicao de foco por nivel concluida:
  - por acao: `Tempo de foco` exibido de forma consistente na tela de acoes;
  - por meta: `Tempo de foco total` exibido no card da meta na aba `Suas Metas`.
- Cobertura de testes expandida para a 5.7:
  - resumo com `streak atual` e `melhor streak`;
  - exibicao de tempo total da meta;
  - exibicao de tempo por acao inclusive em `0min`.
- Validacao executada com suite completa de testes (`flutter test -r compact`) sem falhas.

## 20. Visão de Evolução (Pós-MVP)

Possíveis evoluções:
- Sincronização na nuvem
- Conta do usuário
- Metas compartilhadas
- Gamificação
- IA sugerindo planos
- Análise de hábitos

## 21. Filosofia do Projeto

### 1. Entregar valor rápido
Pequenas releases funcionais.

### 2. Simplicidade acima de complexidade
O MVP deve ser simples.

### 3. Aprendizado através da construção
Evoluir como desenvolvedor enquanto constrói um produto real.

## 22. Regra Final do Projeto

Se uma decisão aumentar muito a complexidade do projeto sem aumentar o valor para o usuário, ela deve ser evitada.

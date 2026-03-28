# PROJECT.md - Quebrando Metas

## 1. VisÃ£o do Produto

**Quebrando Metas** Ã© um aplicativo mobile que ajuda o usuÃ¡rio a transformar objetivos grandes em pequenas aÃ§Ãµes executÃ¡veis, permitindo visualizar progresso e manter clareza sobre o prÃ³ximo passo.

O objetivo central Ã© reduzir a sensaÃ§Ã£o de sobrecarga causada por metas grandes e abstratas, tornando o progresso visÃ­vel, simples e motivador.

### Exemplo de Uso

**Meta:**  
Emagrecer

**AÃ§Ãµes:**
- Treinar 3 vezes por semana
- Melhorar alimentaÃ§Ã£o
- Dormir melhor
- Reduzir aÃ§Ãºcar

O usuÃ¡rio pode acompanhar o progresso de cada meta conforme conclui suas aÃ§Ãµes.

## 2. Problema que o App Resolve

Muitas pessoas:
- Definem metas grandes
- NÃ£o sabem por onde comeÃ§ar
- Perdem motivaÃ§Ã£o ao longo do caminho

Isso acontece porque:
- Metas sÃ£o abstratas
- NÃ£o existe divisÃ£o clara em pequenas aÃ§Ãµes
- Progresso nÃ£o Ã© visÃ­vel

O app resolve isso ao permitir:
- Quebrar metas em aÃ§Ãµes pequenas
- Visualizar progresso
- Manter foco na prÃ³xima aÃ§Ã£o

## 3. PÃºblico-alvo (MVP)

UsuÃ¡rios que:
- Querem organizar objetivos pessoais
- Buscam melhorar hÃ¡bitos
- Gostam de ferramentas simples de produtividade

### Exemplos
- Quem quer emagrecer
- Quem quer estudar algo novo
- Quem quer organizar projetos pessoais
- Quem quer melhorar hÃ¡bitos

## 4. Escopo do MVP

O MVP serÃ¡ **local-first**, sem backend.

### Funcionalidades do MVP

UsuÃ¡rio pode:
- Criar uma meta
- Editar uma meta
- Excluir uma meta
- Adicionar aÃ§Ãµes Ã  meta
- Editar aÃ§Ãµes
- Excluir aÃ§Ãµes
- Marcar aÃ§Ãµes como concluÃ­das
- Visualizar progresso da meta
- Ver lista de metas ativas

## 5. Fora do Escopo do MVP

Estas funcionalidades nÃ£o fazem parte do MVP:
- Login
- SincronizaÃ§Ã£o em nuvem
- GamificaÃ§Ã£o
- Ranking
- Compartilhamento social
- NotificaÃ§Ãµes inteligentes
- SugestÃ£o automÃ¡tica de aÃ§Ãµes com IA

Essas ideias ficam para versÃµes futuras.

## 6. Stack TecnolÃ³gica

Este projeto utiliza:
- Flutter
- Dart
- Riverpod (gerenciamento de estado)
- GoRouter (navegaÃ§Ã£o)
- Hive ou Isar (persistÃªncia local)
- `flutter_test`
- `integration_test`

## 7. Estrutura do Projeto

A estrutura segue organizaÃ§Ã£o por features.

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

Mas abstraÃ§Ãµes desnecessÃ¡rias devem ser evitadas no MVP.

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

### Action (AÃ§Ã£o)

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
- 4 aÃ§Ãµes
- 2 concluÃ­das
- Progresso = 50%

## 9. Fluxo Principal do UsuÃ¡rio

Fluxo bÃ¡sico do app:
1. UsuÃ¡rio abre o app
2. Visualiza lista de metas
3. Cria uma nova meta
4. Adiciona aÃ§Ãµes
5. Marca aÃ§Ãµes como concluÃ­das
6. Visualiza progresso da meta

Esse Ã© o core loop do produto.

### 9.1 EspecificaÃ§Ã£o da Home (MVP)

#### Topo
- SaudaÃ§Ã£o curta
- Quantidade de metas ativas
- Progresso mÃ©dio das metas ativas

FÃ³rmula de progresso mÃ©dio:

```text
progresso_medio = soma(progress_das_metas) / quantidade_de_metas_ativas
```

Regra para estado vazio:
- Se nÃ£o houver metas ativas, exibir `0 metas ativas` e `Progresso mÃ©dio: 0%`

#### Card de destaque: Continue de onde parou
- Exibe meta em andamento
- Exibe progresso da meta
- Exibe prÃ³xima aÃ§Ã£o pendente
- BotÃ£o `Continuar`

Regra inicial de seleÃ§Ã£o da meta destacada:
- Escolher a primeira meta ativa da lista ordenada
- OrdenaÃ§Ã£o padrÃ£o da Home:
- Primeiro metas com aÃ§Ãµes pendentes
- Depois metas com menor progresso
- Em empate, meta mais antiga (`createdAt`)

#### SeÃ§Ã£o: Suas metas
Cada card de meta deve mostrar:
- Nome da meta
- Barra de progresso
- Percentual
- `x de y aÃ§Ãµes concluÃ­das`
- PrÃ³xima aÃ§Ã£o pendente

#### AÃ§Ã£o principal da tela
- BotÃ£o flutuante: `+ Nova Meta`

#### Estados obrigatÃ³rios da Home
- `loading`
- `withData`
- `empty`
- `error` (com aÃ§Ã£o de tentar novamente)

#### CritÃ©rios de aceite da Home
- UsuÃ¡rio entende em poucos segundos quantas metas ativas possui
- UsuÃ¡rio visualiza progresso mÃ©dio e progresso por meta
- UsuÃ¡rio identifica a prÃ³xima aÃ§Ã£o a executar
- UsuÃ¡rio consegue iniciar criaÃ§Ã£o de meta pela aÃ§Ã£o principal
- Interface mantÃ©m linguagem orientada a `aÃ§Ãµes`, nunca `etapas`

### 9.2 NavegaÃ§Ã£o inicial com GoRouter
- O app usa `MaterialApp.router`
- Rotas base:
- `/` para Dashboard (Home)
- `/onboarding` para Onboarding
- Redirect inicial:
- Se onboarding nÃ£o concluÃ­do, abrir `/onboarding`
- Se onboarding concluÃ­do, abrir `/`
- No Sprint 0, a flag de onboarding pode ser mock/local atÃ© a persistÃªncia ser implementada

## 10. PrincÃ­pios de Arquitetura

### 1. Simplicidade
Evitar overengineering.

### 2. SeparaÃ§Ã£o de responsabilidades
Evitar lÃ³gica de negÃ³cio dentro de widgets.

### 3. Widgets pequenos
Preferir componentes como:
- `GoalCard`
- `ActionTile`
- `ProgressIndicator`
- `GoalForm`

### 4. Feature-first
Organizar cÃ³digo por feature, nÃ£o por camada global.

## 11. Regras de CÃ³digo

ConvenÃ§Ãµes:
- Nomes em inglÃªs
- VariÃ¡veis descritivas
- MÃ©todos pequenos
- Evitar widgets muito grandes
- Evitar lÃ³gica complexa no `build()`

Exemplo correto:
- `GoalProgressCalculator`
- `GoalRepository`
- `GoalController`

Evitar:
- `UtilsHelperServiceManager`

## 12. EstratÃ©gia de Testes

### Unit Tests
Testar regras de negÃ³cio:
- CÃ¡lculo de progresso
- ValidaÃ§Ã£o de meta
- ValidaÃ§Ã£o de aÃ§Ãµes

### Widget Tests
Testar interface:
- RenderizaÃ§Ã£o da lista
- FormulÃ¡rio de criaÃ§Ã£o
- Barra de progresso

### Integration Tests
Fluxo mÃ­nimo:
- Criar meta
- Adicionar aÃ§Ãµes
- Concluir aÃ§Ã£o
- Progresso atualizado

## 13. CritÃ©rios de Pronto

Uma feature Ã© considerada pronta quando:
- Funciona corretamente
- NÃ£o quebra anÃ¡lise estÃ¡tica
- Possui testes adequados
- Segue padrÃ£o do projeto
- NÃ£o adiciona complexidade desnecessÃ¡ria

## 14. Workflow de Desenvolvimento

Cada feature segue:
1. Definir micro-objetivo
2. Pedir plano para IA
3. Implementar em pequenos blocos
4. Testar
5. Revisar arquitetura
6. Atualizar `PROJECT.md` se necessÃ¡rio
7. Commit pequeno

## 15. Uso da IA no Projeto

A IA atua como par de programaÃ§Ã£o.

Pode ajudar com:
- Boilerplate
- Widgets
- Testes
- Refactors
- AnÃ¡lise de cÃ³digo

NÃ£o deve decidir sozinha:
- Arquitetura grande
- MudanÃ§as de stack
- Escopo do produto

## 16. Regras para InteraÃ§Ã£o com IA

Sempre pedir:
- Plano curto
- Arquivos a alterar
- Modelo de dados
- Testes necessÃ¡rios
- Ordem de implementaÃ§Ã£o

Evitar pedidos como:
- "Crie o app inteiro"

Preferir:
- "Vamos implementar a feature X em pequenos passos"

## 17. EstratÃ©gia de Branches

Branches principais:
- `main`
- `develop`

Branches de feature:
- `feature/create-goal`
- `feature/goal-actions`
- `feature/goal-progress`

## 18. Convençãoo de Commits - pode ser em portugues

- `feat: add goal creation flow`
- `feat: implement goal actions`
- `test: add goal progress tests`
- `refactor: simplify goal controller`
- `fix: correct progress calculation`

## 19. Roadmap do MVP

### Sprint 0 - FundaÃ§Ã£o
- Status: ConcluÃ­do em 11/03/2026
- Criar projeto âœ…
- Configurar estrutura âœ…
- Criar `PROJECT.md` âœ…
- Configurar router âœ…
- Criar home inicial âœ…

Entregas registradas:
- Estrutura base `app/core/features` criada
- NavegaÃ§Ã£o inicial com `GoRouter` configurada
- Home MVP inicial implementada (topo, destaque, lista e CTA principal)

### Sprint 1 - Metas
- Status: ConcluÃ­do em 11/03/2026
- Lista de metas âœ…
- Criar meta âœ… (fluxo inicial)
- Editar meta âœ…
- Excluir meta âœ… 
- PersistÃªncia local âœ… (metas com Hive)

### Sprint 2 - AÃ§Ãµes
- Status: ConcluÃ­do em 11/03/2026
- Adicionar aÃ§Ãµes âœ…
- Listar aÃ§Ãµes âœ…
- Editar aÃ§Ãµes âœ…
- Excluir aÃ§Ãµes âœ…


### Sprint 3 - Progresso
- Status: ConcluÃ­do em 12/03/2026
- Concluir aÃ§Ãµes âœ…
- Calcular progresso âœ…
- Exibir progresso âœ…
- Metas -> retorno da tela de meta sem estado "Tentar novamente" âœ… (teste com 10 ciclos de ida e volta)
- AÃ§Ãµes e Metas -> input extremo tratado com `inputFormatter` + `validator` + feedback visual âœ…

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
- Status: Concluido (atualizado em 20/03/2026)

Referencia funcional detalhada:
- Ver `README.md` -> `Modo Foco (Sprint 5 - Entregue)`

Regra oficial de streak:
- O streak conta somente quando uma sessao de foco contabiliza `>= 5 minutos`.
- Conclusao manual da acao nao incrementa streak.
- Se passar 1 dia sem foco elegivel, streak zera.

Etapas pequenas de implementacao:

1. Etapa 5.1 - Modelo de dados e persistencia
- [x] Criar entidade `FocusSession` (id, actionId, goalId, startedAt, endedAt, durationMinutes, status).
- [x] Adicionar campos de tempo acumulado na acao (`totalFocusMinutes`) e data do ultimo foco.
- [x] Atualizar mappers e repositorio local para salvar os novos campos.

2. Etapa 5.2 - Fluxo de inicio do foco
- [x] Habilitar CTA `Iniciar foco` ao selecionar uma acao.
- [x] Permitir escolher duracao pre-definida (15, 30, 60 minutos).
- [x] Iniciar timer em tela dedicada/modal com estado reativo.

3. Etapa 5.3 - Tela durante foco
- [x] Exibir nome da meta, nome da acao, tempo restante e botao de cancelar.
- [x] Manter experiencia direta, sem exigir navegacao extra.
- [x] Em cancelamento, registrar sessao cancelada e aplicar regra de acumulacao real de tempo.

4. Etapa 5.4 - Finalizacao do foco
- [x] Ao concluir timer, registrar sessao concluida e mostra tempo gasto.
- [x] Incrementar automaticamente `totalFocusMinutes` da acao.
- [x] Atualizar agregado de tempo da meta (soma das acoes da meta).
- [x] Nao concluir acao automaticamente.
- [x] Ao cancelar, o tempo acumulado conta somente com `>= 1 minuto` de foco; abaixo disso nao soma. 

5. Etapa 5.5 - Conclusao manual da acao
- [x] Implementar conclusao manual por gesto (ex: swipe lateral). remover bolinha de seleÃ§Ã£o e manter a seleÃ§Ã£o onde hoje Ã© a conclusÃ£o da aÃ§Ã£o. ConclusÃ£o passa a ser por swipe lateral.
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


### Sprint 6  - UI/UX Definitiva
- Status: Em andamento (atualizado em 26/03/2026)

Objetivo do sprint:
- Consolidar a UX principal em 1 home, com layout moderno/clean.
- Refatorar a tela de detalhe da meta mantendo regras atuais.
- Nao introduzir conceito de Etapas.

Etapas pequenas de implementacao:

1. Etapa 6.1 - Consolidacao da navegacao principal
- [x] Voltar de 2 abas para 1 experiencia principal.
- [x] Manter compatibilidade de rotas existentes (/ e /goals) sem quebrar fluxo.
- [x] Manter FAB de criacao de meta no fluxo principal.

2. Etapa 6.2 - Refactor visual da Home
- [x] Cabecalho com saudacao + chips de streak e horas investidas.
- [x] Card CONTINUE DE ONDE PAROU com progresso linear, proxima acao e CTA Continuar.
- [x] Secao Suas Metas em cards compactos com percentual + barra linear.
- [x] Estado vazio amigavel e fallback sem bloquear uso.

3. Etapa 6.3 - Refactor visual da tela de detalhe da meta
- [x] AppBar simplificada.
- [x] Bloco superior com progresso linear e percentual numerico (sem grafico circular).
- [x] Informacoes da meta (titulo + descricao) e metricas (Tempo total + Sequencia).
- [x] Lista direta de acoes da meta (sem agrupamento por etapas).

4. Etapa 6.4 - Responsividade e robustez visual
- [x] Ajustes de layout para telas menores (modo compacto).
- [x] Correcao de cenarios de overflow em fluxos de foco e lista.
- [ ] Revisao visual final em breakpoints extremos (muito pequeno e tablet).

5. Etapa 6.5 - Testes e regressao de UI
- [x] Readaptar widget tests para a nova composicao visual.
- [x] Atualizar finders/keys de cenarios de prioridade, foco e navegacao.
- [x] Validar suite completa (flutter test -r compact) sem falhas.
- [x] Atualizar/introduzir golden tests da nova Home e detalhe da meta.

6. Etapa 6.6 - Fechamento documental
- [x] Registrar entregas e estado do sprint no Project.md.
- [x] Sincronizar README.md com a UI final do Sprint 6 (estrutura, regras e estado atual de testes).

7. Etapa 6.7 - Diagnostico e regras de exibicao
- [x] Verificar e documentar a regra atual de exibicao da Proxima acao no card Continue de onde parou.
- [x] Verificar escopo da metrica Sequencia: confirmar se reflete a meta atual ou o total geral de dias seguidos.
- [x] Investigar por que as 3 metas prioritarias nao estao sendo exibidas e registrar causa raiz.

8. Etapa 6.8 - Ajustes de UI na Tela de Meta
- [x] Reposicionar o bloco de progresso para ficar abaixo do card de descricao da meta.
- [x] Ajustar o FAB da tela de meta para icone-only, removendo o texto Nova acao.
- [x] Remover o icone > do card das acoes.
- [x] Melhorar a UI do botao Iniciar foco (ligeiramente maior, mantendo responsividade).

9. Etapa 6.9 - Ajustes de UI na Tela Principal
- [x] Centralizar Ola!, dias seguidos e horas investidas no header.
- [x] Ajustar o header para manter composicao limpa com: Ola!, metricas e card Continue de onde parou.
- [x] Reduzir levemente o tamanho dos meta cards dentro do card Continue de onde parou.
- [x] Retirar apenas o texto "Completo" de 20% completo
- [x] Reduzir o botao Continuar e posicionar ao lado da informacao de acao.
- [x] Restaurar exibicao das 3 metas prioritarias no fluxo principal, mantendo a regra de prioridade existente.

10. Etapa 6.10 - Novo Modo Foco (mini tarefas)

1. Etapa 6.10.1 - Entrada no foco e navegacao
- [x] Manter inicio do foco em `GoalActionsPage` pelo botao fixo inferior `Iniciar foco`.
- [x] Manter habilitacao do botao apenas com 1 acao selecionada e pendente.
- [x] Migrar experiencia de foco de `AlertDialog` para `Page` dedicada.

2. Etapa 6.10.2 - Regras de bloqueio de saida
- [x] Bloquear qualquer saida da page de foco enquanto a sessao estiver ativa.
- [x] Permitir sair da page apenas pelos botoes `Cancelar` (durante foco) e `Fechar` (apos conclusao).
- [x] Bloquear retorno por back button/gesture durante sessao ativa.

3. Etapa 6.10.3 - Seletor de duracao
- [x] Manter seletor em `bottom sheet` antes de iniciar foco.
- [x] Atualizar opcoes para `15`, `30` e `60` minutos.

4. Etapa 6.10.4 - Timer e contagem real
- [x] Rodar timer com base no relogio real (persistindo comportamento em background/retorno ao app).
- [x] Exibir contador regressivo em `mm:ss` na page de foco.
- [x] Recalcular tempo restante corretamente ao voltar para o app.

5. Etapa 6.10.5 - Regras de concluir/cancelar
- [x] Manter regra atual de `Concluir agora` (tempo realmente decorrido).
- [x] Manter regra atual ao zerar contador (conclusao + resumo final).
- [x] Em `Cancelar`, somar tempo apenas quando houver `>= 1 minuto` decorrido.
- [x] Em `Cancelar` com `< 1 minuto`, nao somar tempo.

6. Etapa 6.10.6 - UI dedicada e animacoes leves
- [x] Criar layout de foco dedicado com:
  - nome da meta,
  - nome da acao,
  - timer,
  - botoes `Cancelar` / `Concluir agora` / `Fechar` (estado final).
- [x] No estado concluido, exibir `Sessao concluida` + `Tempo investido: X min`.
- [x] Aplicar animacoes leves:
  - entrada da tela (fade + slide curto),
  - pulso suave no contador,
  - transicao visual no estado concluido.

7. Etapa 6.10.7 - Testes e regressao
- [x] Atualizar widget tests para o novo fluxo em page dedicada.
- [x] Cobrir bloqueio de saida por back/gesture.
- [x] Cobrir timer com base em relogio real no retorno de background.
- [x] Cobrir cancelamento com `< 1 min` (nao soma) e `>= 1 min` (soma).

11. Etapa 6.11 - Refinos de UX no Modo Foco (novo)

1. Etapa 6.11.1 - Correcao de regra do streak
- [x] Ajustar regra para nao incrementar streak quando o usuario iniciar foco e cancelar antes de 5 minuto.
- [x] Definir incremento de streak somente quando houver tempo de foco contabilizado na sessao (>= 5 minuto).
- [x] Garantir consistencia com `bestStreak` e sem regressao nas regras atuais.
- [x] Incluir testes que asseguram a funcionalidade.

2. Etapa 6.11.2 - Padronizacao de linguagem PT-BR
- [x] Corrigir textos sem acentuacao na UI (ex: `Acao` -> `Ação`, `Descricao` -> `Descrição`).
- [x] Padronizar nomenclaturas de foco/meta/acao em labels, mensagens e feedbacks.
- [x] Revisar textos de estados vazios e erro para tom consistente.

3. Etapa 6.11.3 - Botao para aumentar tempo de foco (+5 min)
- [x] Adicionar botao ao lado do relogio no Modo Foco para incrementar +5 minutos por toque.
- [x] Atualizar `remaining`, `duration` e `expectedEndAt` mantendo o timer por relogio real.
- [x] Preservar comportamento de UI em rotacao/background sem overflow.

4. Etapa 6.11.4 - Regra de contabilizacao com tempo estendido
- [x] Garantir que minutos adicionados por +5 sejam considerados no calculo final ao concluir foco.
- [x] Garantir que minutos adicionados sejam considerados nas regras de cancelamento (>= 1 min).
- [x] Validar acumulacao correta em meta/acao apos sessoes com extensao de tempo.

5. Etapa 6.11.5 - Mensagens motivacionais por marcos de foco (adiada)
- [x] Escopo adiado por decisao de UX (risco de repeticao e baixo ganho percebido).
- [x] Manter fluxo de foco sem mensagens motivacionais no Sprint 6.
- [x] Reavaliar no pos-MVP apenas se houver proposta de dinamica nao repetitiva.

6. Etapa 6.11.6 - Testes e regressao dos novos refinamentos
- [x] Widget tests para streak sem incremento em cancelamento < 5 min.
- [x] Widget tests para botao +5 min refletindo no timer e no acumulado final.
- [x] Remover cobertura de mensagens motivacionais deste sprint (escopo adiado na 6.11.5).
- [x] Revalidar `flutter test -r compact` e atualizar goldens apenas se houver impacto visual esperado.

### Sprint 7 - Onboarding (Refino de Experiencia Inicial)
- Status: Em andamento (reaberto em 27/03/2026)

Objetivo do sprint:
- Refinar a experiencia da `OnboardingPage` sem quebrar o fluxo atual de navegacao e persistencia.
- Tornar o onboarding mais claro, curto e orientado a acao para melhorar ativacao inicial.

Etapas pequenas de implementacao:

1. Etapa 7.1 - Diagnostico do fluxo atual
- [x] Mapear comportamento atual da `OnboardingPage` e do `redirect` no `GoRouter`.
- [x] Validar criterios de entrada/saida do onboarding com base em `OnboardingStatus`.
- [x] Registrar riscos de regressao de navegacao.

2. Etapa 7.2 - Refino de conteudo e estrutura
- [x] Revisar copy dos passos com linguagem clara e objetiva.
- [x] Reduzir ruido visual e reforcar CTA principal de conclusao.
- [x] Garantir hierarquia visual consistente com o restante da UI do app.

3. Etapa 7.3 - Interacao e acessibilidade
- [x] Ajustar estados de botoes (habilitado/desabilitado/loading) no fluxo.
- [x] Garantir responsividade em telas pequenas e em rotacao.
- [x] Revisar semantica basica para leitores de tela e contraste dos elementos.

4. Etapa 7.4 - Persistencia e navegacao segura
- [x] Confirmar que concluir onboarding persiste estado e evita reabertura indevida.
- [x] Garantir retorno correto para Home apos conclusao.
- [x] Cobrir cenarios de inicializacao fria (cold start) com onboarding concluido e nao concluido.

5. Etapa 7.5 - Testes e regressao
- [x] Widget tests do fluxo completo de onboarding (entrada, avancar, concluir).
- [x] Testes de navegacao para `redirect` com onboarding concluido/pendente.
- [x] Revalidar `flutter test -r compact` ao final.

6. Etapa 7.6 - Personalizacao da saudacao inicial
- [x] Adicionar captura de nome no onboarding.
- [x] Persistir nome do usuario em configuracao local.
- [x] Exibir saudacao personalizada na Home (ex: `Olá, Nome!`).
- [x] Variar saudacao ocasionalmente (`Olá`, `Oi`, `Bem vindo de volta`, `Eai`) sem quebrar fallback.

7. Etapa 7.7 - Alteracao de nome nas configuracoes (Drawer)
- [x] Adicionar entrada `Alterar nome` no Drawer de configuracoes.
- [x] Abrir dialog simples com campo de nome e validacao basica.
- [x] Persistir nome com `OnboardingStatus.setDisplayName`.
- [x] Atualizar saudacao da Home imediatamente apos salvar.
- [x] Exibir feedback de erro amigavel em caso de falha ao salvar.

8. Etapa 7.8 - Onboarding informativo apos coleta de nome
- [x] Transformar onboarding em fluxo de 2 momentos:
  - coletar nome,
  - exibir bloco `Como funciona` antes de finalizar.
- [x] Incluir explicativo curto em 4 pontos:
  - criar meta,
  - adicionar acoes,
  - usar modo foco,
  - acompanhar progresso e streak.
- [x] Manter CTA final claro para concluir onboarding e entrar na Home.
- [x] Garantir consistencia visual com a UI atual (tipografia, espacamento e estados).
- [x] Garantir responsividade em tela pequena e rotacao no fluxo completo.
- [x] Alterar linguagem da UI da aplicação, adicionando as acentuações de palavras (Ex: Configurações)

9. Etapa 7.9 - Testes e regressao das novas etapas
- [x] Widget test para alterar nome pelo Drawer e refletir na Home.
- [x] Widget tests para fluxo onboarding em 2 momentos (nome -> explicativo -> concluir).
- [x] Revalidar `flutter test -r compact` ao final das implementacoes.

### Sprint 8 - Release MVP
- Testes finais
- RevisÃ£o
- Build release
- Roadmap V2

## DecisÃµes tÃ©cnicas (12/03/2026)

- NavegaÃ§Ã£o de ediÃ§Ã£o/aÃ§Ãµes de metas refatorada para `goalId` em path params, removendo dependÃªncia de `state.extra`.
- Estado de onboarding movido para storage local com Hive + `ChangeNotifier` (`refreshListenable` no `GoRouter`).
- PersistÃªncia local tipada com `Map<String, dynamic>` em mappers e repositÃ³rio.
- Home ajustada para considerar apenas metas ativas no topo e no progresso mÃ©dio.
- Fluxo de aÃ§Ãµes estabilizado com atualizaÃ§Ã£o explÃ­cita da Home apÃ³s mutaÃ§Ãµes.
- ValidaÃ§Ã£o centralizada por `TitleValidator` com limite de caracteres tambÃ©m no input (`LengthLimitingTextInputFormatter`).
- Tratamento de erro de UI padronizado com `SnackBar` em criaÃ§Ã£o/ediÃ§Ã£o de metas e aÃ§Ãµes.
- Cobertura de testes ampliada para:
- usuÃ¡rio com histÃ³rico longo (10 metas concluÃ­das + 5 ativas)
- CRUD de aÃ§Ãµes,
- input extremo (tÃ­tulo e descriÃ§Ã£o longos),
- estabilidade no retorno da tela de aÃ§Ãµes (10 ciclos sem estado de retry).

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
  - `completedAt` e recÃ¡lculo de progresso seguem pelo fluxo de atualizacao da acao;
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

### Atualizacao tecnica (19/03/2026 - Sprint 6)

- Home principal consolidada em uma experiencia unica (sem abas visuais).
- Compatibilidade de rotas preservada:
  - / segue como entrada principal;
  - /goals mantida por compatibilidade e apontando para a mesma experiencia da Home.
- Dashboard refatorada para o novo padrao visual:
  - cabecalho com Ola!, streak e horas investidas;
  - card CONTINUE DE ONDE PAROU com progresso linear, proxima acao e CTA;
  - secao Suas Metas com cards compactos e hierarquia visual simplificada.
- Tela de detalhe da meta (goal-actions) refeita sem Etapas:
  - bloco de progresso linear + percentual;
  - informacoes da meta;
  - metricas de tempo total e sequencia;
  - lista direta de acoes.
- Regras de negocio preservadas (prioridade ate 3 metas, foco, conclusao manual e persistencia).
- Testes de widget readaptados para nova estrutura visual e seletores atualizados.
- Validacao executada:
  - flutter test test/widget_test.dart -r compact --concurrency=1
  - flutter test -r compact
  - Resultado: suite verde, sem falhas.

### Atualizacao tecnica (19/03/2026 - Sprint 6.7)

- Regra de exibicao da `Proxima acao` validada e documentada:
  - o card `Continue de onde parou` usa a acao pendente com menor `totalFocusMinutes`;
  - em empate de foco, a exibicao segue a menor `order`.
- Escopo de `Sequencia` validado:
  - na tela da meta, a metrica e calculada por `listFocusSessions(goalId: goal.id)`;
  - portanto, a sequencia exibida e da meta atual (nao o total global).
- Causa raiz registrada para "sumico" das 3 prioridades na home:
  - no refactor do Sprint 6, o destaque `Continue de onde parou` passou a selecionar apenas 1 meta (`prioritizedGoals.first`);
  - a regra de prioridade (0..3) continua ativa no dominio, mas a composicao visual atual do destaque mostra somente a primeira.
- Cobertura de testes adicionada para 6.7:
  - validacao da regra da `Proxima acao` (pendente com menor foco; desempate por ordem);
  - validacao de escopo da `Sequencia` por meta.

### Atualizacao tecnica (19/03/2026 - Sprint 6.5)

- Golden tests adicionados para cobertura visual da UI final do Sprint 6:
  - `test/ui_golden_test.dart` com cenario da Home principal;
  - `test/ui_golden_test.dart` com cenario da tela de detalhe da meta.
- Baselines gerados em:
  - `test/goldens/dashboard_home_sprint6.png`;
  - `test/goldens/goal_detail_sprint6.png`.
- Validacao executada:
  - `flutter test test/ui_golden_test.dart --update-goldens -r compact --concurrency=1`;
  - `flutter test test/ui_golden_test.dart -r compact --concurrency=1`;
  - `flutter test -r compact`.

### Atualizacao tecnica (19/03/2026 - Sprint 6.8/6.9)

- Tela de meta ajustada na ordem visual:
  - descricao exibida antes do bloco de progresso linear;
  - FAB de nova acao convertido para icone-only;
  - icone de seta (`>`) removido dos cards de acao;
  - botao `Iniciar foco` com altura ligeiramente maior para melhorar toque.
- Home refinada para fechamento da 6.9:
  - header centralizado com `Ola!`, dias seguidos e horas investidas;
  - card `Continue de onde parou` com metas prioritarias mais compactas;
  - percentual simplificado (`20%`, sem sufixo `completo`);
  - botao `Continuar` mantido ao lado da proxima acao com tamanho reduzido.
- Cobertura de testes ampliada:
  - novo teste de centralizacao do header;
  - novo teste da tela de meta para garantir descricao acima do progresso e ausencia do chevron.

### Atualizacao tecnica (20/03/2026 - Consolidacao do estado atual)

- Home consolidada em 1 experiencia real:
  - rota `/goals` mantida por compatibilidade, apontando para o mesmo layout de `DashboardPage`.
- Regra final do card `Continue de onde parou` estabilizada:
  - exibe ate 3 metas prioritarias (`priorityRank`) em ordem de prioridade;
  - regra de `Proxima acao` usa pendente com menor `totalFocusMinutes`;
  - em empate, usa menor `order`.
- Modo foco consolidado em page dedicada com bloqueio de saida:
  - back button/gesture bloqueados durante sessao ativa;
  - saida permitida apenas por `Cancelar` (durante foco) e `Fechar` (apos concluir).
- Regras finais de foco documentadas conforme implementacao atual:
  - duracoes disponiveis: `15`, `30`, `60` minutos;
  - contador baseado em relogio real com recalculo no retorno de background;
  - `Concluir agora` habilita somente apos `>= 5` minutos decorridos;
  - `Cancelar` acumula tempo somente com `>= 1` minuto (menos que isso nao soma);
  - ao cancelar depois de mais de 2 minutos, UI informa minutos contabilizados.
- Refinos de UI da Home aplicados no card `Continue de onde parou`:
  - titulo com maior destaque tipografico;
  - menor espacamento vertical entre cards priorizados;
  - menor padding lateral do card de fundo para ampliar largura util dos cards internos.
- Testes seguem cobrindo as regras acima:
  - widget tests para prioridade (0..3), regra da proxima acao, foco, bloqueio de navegacao e overflows;
  - golden tests da Home e detalhe da meta (`test/ui_golden_test.dart`).

### Atualizacao tecnica (26/03/2026 - Sprint 6.11.1)

- Regra de streak corrigida para contabilizar apenas sessoes com `>= 5 minutos` efetivos.
- `startFocusSession` nao incrementa mais streak nem `bestStreak`.
- Recalculo de `streak` e `bestStreak` acontece ao finalizar sessao (`completed`/`canceled`), com persistencia consistente.
- Elegibilidade do streak passou a usar minutos contabilizados da sessao:
  - sessoes em andamento (`running`) nao contam;
  - sessoes finalizadas usam tempo efetivo (`endedAt - startedAt`) limitado a `durationMinutes`;
  - compatibilidade legada: sessao `completed` sem `endedAt` usa `durationMinutes`.
- Cobertura de testes adicionada/atualizada para:
  - calculadora de streak com corte `< 5 min` e fallback legado;
  - persistencia de streak/bestStreak com foco concluido/cancelado;
  - widget test garantindo que cancelamento com `< 5 min` nao incrementa streak na UI.

### Atualizacao tecnica (26/03/2026 - Sprint 6.11.3)

- Modo Foco recebeu botao `+5 min` ao lado do relogio (key: `focus-add-five-minutes-button`).
- Ao tocar no botao, o fluxo atualiza em conjunto:
  - `duration` da sessao,
  - `remaining` do contador,
  - `expectedEndAt` usado no relogio real.
- Compatibilidade com background/retorno preservada:
  - countdown continua reduzindo por tempo real apos retomar o app.
- Responsividade ajustada para telas pequenas:
  - botao compactado para evitar overflow horizontal no layout do foco.
- Cobertura de widget tests adicionada/validada para:
  - incremento de +5 min com contagem real;
  - retorno de background apos incremento;
  - ausencia de overflow na tela de foco em viewport reduzida.

### Atualizacao tecnica (26/03/2026 - Sprint 6.11.4)

- A duracao efetiva da sessao (incluindo extensoes de +5 min) passou a ser enviada da UI de foco para o controller no momento de `Concluir agora` e `Cancelar`.
- Normalizacao de minutos agora usa a duracao efetiva da sessao para evitar cap indevido na duracao original.
- Resultado pratico:
  - conclusao com tempo estendido contabiliza minutos acima da duracao inicial;
  - cancelamento com tempo estendido tambem contabiliza minutos acima da duracao inicial, respeitando regra de `>= 1 min`.
- Cobertura de widget tests adicionada para cenarios de extensao com acumulacao em acao/meta:
  - concluir foco apos extensao;
  - cancelar foco apos extensao.

### Atualizacao tecnica (26/03/2026 - Sprint 6.11.5/6.11.6)

- Etapa 6.11.5 oficialmente adiada por decisao de UX:
  - mensagens motivacionais removidas do escopo do Sprint 6;
  - motivo: alta chance de repeticao com baixo ganho de valor percebido no fluxo atual.
- Etapa 6.11.6 ajustada para refletir o novo escopo:
  - mantida cobertura de regressao para streak e +5 min;
  - removido item de testes para mensagens motivacionais neste sprint.
- Validacao final da 6.11.6 concluida:
  - widget tests de streak (< 5 min nao incrementa) e +5 min verdes;
  - `flutter test -r compact` executado com sucesso;
  - baseline de golden da Home atualizado para refletir estado visual atual (`dashboard_home_sprint6.png`).

### Atualizacao tecnica (26/03/2026 - Sprint 7.6)

- `OnboardingPage` evoluida de placeholder para fluxo funcional de boas-vindas:
  - campo de nome do usuario com validacao basica;
  - CTA de conclusao (`Comecar`) com estado de salvamento.
- `OnboardingStatus` expandido para persistir:
  - status de conclusao do onboarding;
  - nome do usuario (`displayName`);
  - indice e timestamp da saudacao atual.
- Saudacao da Home passou a ser personalizada e variavel:
  - fallback sem nome: `Olá!` / `Oi!` / `Bem vindo de volta!` / `Eai!`;
  - com nome: `Olá, Nome!` (e variacoes equivalentes).
- Rotacao de saudacao definida com janela temporal para mudar "de vez em quando", mantendo estabilidade durante a sessao.

### Atualizacao tecnica (27/03/2026 - Sprint 7.8)

- Padronizacao de linguagem concluida na UI com acentuacao correta em textos de onboarding, configuracoes e mensagens de erro/ajuda.
- Ajustes aplicados tambem nas saudacoes variaveis da Home (`Bem-vindo de volta` e `E aí`).
- Correcoes pontuais de copy para maior naturalidade em portugues (ex: `Meta adicionada as prioridades` -> `Meta adicionada às prioridades`).

### Atualizacao tecnica (26/03/2026 - Sprint 7.1 a 7.5)

- Diagnostico de fluxo validado:
  - `redirect` do `GoRouter` envia para `/onboarding` quando onboarding nao foi concluido;
  - acesso direto a `/onboarding` com onboarding concluido redireciona para `/`.
- Cold start ajustado:
  - ausencia da flag local agora considera onboarding pendente no `init` do `OnboardingStatus`.
- Onboarding refinado para UX:
  - copy mais direta e curta;
  - botao principal com estados `desabilitado` (sem nome) e `loading` (salvando);
  - layout com scroll seguro para teclado, telas pequenas e rotacao.
- Acessibilidade basica reforcada:
  - heading semantico no titulo de onboarding.
- Cobertura de testes adicionada em `test/features/onboarding/presentation/onboarding_flow_test.dart` para:
  - redirect onboarding pendente/concluido;
  - validacao de nome vazio;
  - conclusao de onboarding com navegacao para Home e saudacao personalizada;
  - comportamento em rotacao de tela.
## 20. VisÃ£o de EvoluÃ§Ã£o (PÃ³s-MVP)

PossÃ­veis evoluções:
- Sincronização na nuvem
- Conta do usuário
- Metas compartilhadas
- Gamificação
- IA sugerindo planos
- Análise de hÃ¡bitos

## 21. Filosofia do Projeto

### 1. Entregar valor rÃ¡pido
Pequenas releases funcionais.

### 2. Simplicidade acima de complexidade
O MVP deve ser simples.

### 3. Aprendizado atravÃ©s da construÃ§Ã£o
Evoluir como desenvolvedor enquanto constrÃ³i um produto real.

## 22. Regra Final do Projeto

Se uma decisão aumentar muito a complexidade do projeto sem aumentar o valor para o usuÃ¡rio, ela deve ser evitada.



### Atualizacao tecnica (27/03/2026 - Perfis de testes)

- Adicionado runner de testes em `scripts/run_tests.ps1` com preflight para reduzir intermitencia no Windows.
- Preflight agora encerra processos `flutter/dart` pendurados e limpa lockfiles/artefatos de teste antes da execucao.
- Perfis disponiveis para execucao incremental:
  - `smoke` (rapido),
  - `regression` (intermediario),
  - `full` (suite completa).
- Testes agora classificados com tags reais (`smoke`, `regression`, `full`) para execucao seletiva em CI/local (`flutter test --tags ...`).

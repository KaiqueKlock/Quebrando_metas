# PROJECT.md - Quebrando Metas

## 1. Visao do Produto

**Quebrando Metas** E um aplicativo mobile que ajuda o usuario a transformar objetivos grandes em pequenas Acoes executaveis, permitindo visualizar progresso e manter clareza sobre o proximo passo.

O objetivo central e reduzir a sensacao de sobrecarga causada por metas grandes e abstratas, tornando o progresso viavel, simples e motivador.

### Exemplo de Uso

**Meta:**  
Emagrecer

**Acoes:**
- Treinar 3 vezes por semana
- Melhorar alimentacao
- Dormir melhor
- Reduzir acucar

O usuario pode acompanhar o progresso de cada meta conforme conclui suas Acoes.

## 2. Problema que o App Resolve

Muitas pessoas:
- Definem metas grandes
- Nao sabem por onde comecar
- Perdem motivacao ao longo do caminho

Isso acontece porque:
- Metas são abstratas
- Nao existe divisao clara em pequenas Acoes
- Progresso nao e visual

O app resolve isso ao permitir:
- Quebrar metas em Acoes pequenas
- Visualizar progresso
- Manter foco na proxima acao

## 3. Publico-alvo (MVP)

Usuarios que:
- Querem organizar objetivos pessoais
- Buscam melhorar habitos
- Gostam de ferramentas simples de produtividade

### Exemplos
- Quem quer emagrecer
- Quem quer estudar algo novo
- Quem quer organizar projetos pessoais
- Quem quer melhorar habitos

## 4. Escopo do MVP

O MVP sera: **local-first**, sem backend.

### Funcionalidades do MVP

Usuário pode:
- Criar uma meta
- Editar uma meta
- Excluir uma meta
- Adicionar Acoes as  meta
- Editar Acoes
- Excluir Acoes
- Marcar Acoes como concluídas
- Visualizar progresso da meta
- Ver lista de metas ativas

## 5. Fora do Escopo do MVP

Estas funcionalidades nao fazem parte do MVP:
- Login
- Sincronizacao em nuvem
- Gamificação
- Ranking
- Compartilhamento social
- Notificacoes inteligentes
- Sugestao automatica de Acoes com IA

Essas ideias ficam para Versoes futuras.

## 6. Stack Tecnologica

Este projeto utiliza:
- Flutter
- Dart
- Riverpod (gerenciamento de estado)
- GoRouter (navegação)
- Hive ou Isar (persistencia local)
- `flutter_test`
- `integration_test`

## 7. Estrutura do Projeto

A estrutura segue organizacao por features.

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

Mas abstracoes desnecessarias devem ser evitadas no MVP.

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
- 4 Acoes
- 2 concluídas
- Progresso = 50%

## 9. Fluxo Principal do Usuario

Fluxo básico do app:
1. Usuario abre o app
2. Visualiza lista de metas
3. Cria uma nova meta
4. Adiciona Acoes
5. Marca Acoes como concluídas
6. Visualiza progresso da meta

Esse e o core loop do produto.

### 9.1 Especificação da Home (MVP)

#### Topo
- Saudacao curta
- Quantidade de metas ativas
- Progresso medio das metas ativas

Formula de progresso médio:

```text
progresso_medio = soma(progress_das_metas) / quantidade_de_metas_ativas
```

Regra para estado vazio:
- Se nao houver metas ativas, exibir `0 metas ativas` e `Progresso medio: 0%`

#### Card de destaque: Continue de onde parou
- Exibe meta em andamento
- Exibe progresso da meta
- Exibe Proxima acao pendente
- Botao `Continuar`

Regra inicial de selecao da meta destacada:
- Escolher a primeira meta ativa da lista ordenada
- Ordenacao padrão da Home:
- Primeiro metas com Acoes pendentes
- Depois metas com menor progresso
- Em empate, meta mais antiga (`createdAt`)

#### Sessao: Suas metas
Cada card de meta deve mostrar:
- Nome da meta
- Barra de progresso
- Percentual
- `x de y Acoes concluídas`
- Proxima acao pendente

#### Acao principal da tela
- Botao flutuante: `+ Nova Meta`

#### Estados obrigatorios da Home
- `loading`
- `withData`
- `empty`
- `error` (com ação de tentar novamente)

#### Criterios de aceite da Home
- Usuario entende em poucos segundos quantas metas ativas possui
- Usuario visualiza progresso medio e progresso por meta
- Usuario identifica a proxima acao a executar
- Usuario consegue iniciar criacao de meta pela acao principal
- Interface mantem linguagem orientada a `Acoes`, nunca `etapas`

### 9.2 Navegacao inicial com GoRouter
- O app usa `MaterialApp.router`
- Rotas base:
- `/` para Dashboard (Home)
- `/onboarding` para Onboarding
- Redirect inicial:
- Se onboarding não concluido, abrir `/onboarding`
- Se onboarding concluido, abrir `/`
- No Sprint 0, a flag de onboarding pode ser mock/local ate a persistencia ser implementada

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
Organizar codigo por feature, nao por camada global.

## 11. Regras de Codigo

Convencoes:
- Nomes em ingles
- Variaveis descritivas
- Metodos pequenos
- Evitar widgets muito grandes
- Evitar logica complexa no `build()`

Exemplo correto:
- `GoalProgressCalculator`
- `GoalRepository`
- `GoalController`

Evitar:
- `UtilsHelperServiceManager`

## 12. Estrategia de Testes

### Unit Tests
Testar regras de negócio:
- Calculo de progresso
- Validacao de meta
- Validacao de Acoes

### Widget Tests
Testar interface:
- Renderizacao da lista
- Formulario de criacao
- Barra de progresso

### Integration Tests
Fluxo minimo:
- Criar meta
- Adicionar Acoes
- Concluir Acoes
- Progresso atualizado

## 13. Criterios de Pronto

Uma feature e considerada pronta quando:
- Funciona corretamente
- Nao quebra analise estatica
- Possui testes adequados
- Segue padrao do projeto
- Nao adiciona complexidade desnecessaria

## 14. Workflow de Desenvolvimento

Cada feature segue:
1. Definir micro-objetivo
2. Pedir plano para IA
3. Implementar em pequenos blocos
4. Testar
5. Revisar arquitetura
6. Atualizar `PROJECT.md` se necessario
7. Commit pequeno

## 15. Uso da IA no Projeto

A IA atua como par de programação.

Pode ajudar com:
- Boilerplate
- Widgets
- Testes
- Refactors
- Analise de codigo

Nao deve decidir sozinha:
- Arquitetura grande
- Mudancas de stack
- Escopo do produto

## 16. Regras para Interação com IA

Sempre pedir:
- Plano curto
- Arquivos a alterar
- Modelo de dados
- Testes necessarios
- Ordem de implementacao

Evitar pedidos como:
- "Crie o app inteiro"

Preferir:
- "Vamos implementar a feature X em pequenos passos"

## 17. Estrategia de Branches

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
- Criar projeto
- Configurar estrutura 
- Criar `PROJECT.md`
- Configurar router 
- Criar home inicial…

Entregas registradas:
- Estrutura base `app/core/features` criada
- Navegação inicial com `GoRouter` configurada
- Home MVP inicial implementada (topo, destaque, lista e CTA principal)

### Sprint 1 - Metas
- Status: Concluído em 11/03/2026
- Lista de metas
- Criar meta  (fluxo inicial)
- Editar meta 
- Excluir meta  
- Persistencia local  (metas com Hive)

### Sprint 2 - Acoes
- Status: Concluído em 11/03/2026
- Adicionar Acoes 
- Listar Acoes 
- Editar Acoes 
- Excluir Acoes


### Sprint 3 - Progresso
- Status: Concluído em 12/03/2026
- Concluir Acoes 
- Calcular progresso
- Exibir progresso 
- Metas -> retorno da tela de meta sem estado "Tentar novamente"(teste com 10 ciclos de ida e volta)
- Acoes e Metas -> input extremo tratado com `inputFormatter` + `validator` + feedback visual ✅

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

### Sprint 8 - Flexibilidade de Uso (Modo Checklist) + Card Semanal
- Status: Em andamento (30/03/2026)

Objetivo do sprint:
- Permitir uso do app sem obrigatoriedade do Modo Foco (fluxo checklist).
- Trocar o card `Progresso da meta` por um card semanal com status diario por acao.
- Preparar base tecnica para futura feature mensal sem acoplar UI agora.

Etapas pequenas de implementacao:

1. Etapa 8.1 - Definicao funcional e regras de negocio
- [x] Definir regra unica para "meta feita no dia" em dois modos:
  - foco ativo: dia valido com >= 5 min de foco na meta;
  - foco desativado: dia valido com confirmacao manual de acao feita.
- [x] Definir comportamento idempotente da confirmacao diaria (nao duplicar no mesmo dia).
- [x] Documentar regra de prioridade entre swipe e confirmacao diaria (swipe controla `isCompleted`; confirmacao diaria conta apenas para status do dia).

2. Etapa 8.2 - Configuracao: Modo Foco ativado/desativado
- [x] Adicionar flag global persistida em configuracoes locais (ex: `focusModeEnabled`).
- [x] Exibir toggle no Drawer de configuracoes.
- [x] Aplicar mudanca em tempo real na UI sem precisar reiniciar app.

3. Etapa 8.3 - Tela de acoes com Modo Foco desativado
- [x] Ocultar selecao de acao para foco e CTA `Iniciar foco` quando `focusModeEnabled = false`.
- [x] Exibir botao de confirmacao diaria por acao (texto atual: `Confirmar`).
- [x] Manter swipe para concluir/reabrir acao no fluxo checklist.

4. Etapa 8.4 - Persistencia da confirmacao diaria
- [x] Registrar confirmacao por data para cada acao (timestamp local).
- [x] Garantir leitura por dia para alimentar card semanal da meta.
- [x] Validar migracao/compatibilidade com dados legados (sem quebrar foco atual).

5. Etapa 8.5 - Troca de card: `Progresso da meta` -> `Card semanal`
- [x] Entrega inicial do card semanal na Home (Dashboard) concluida.
- [x] Exibir 7 dias da semana no card semanal (layout compacto).
- [x] Aplicar estado visual:
  - verde para dia confirmado;
  - vermelho para dia nao confirmado.
- [ ] (Backlog de refinamento) Reavaliar remocao do card linear na tela de detalhe da meta.

6. Etapa 8.6 - Regra de preenchimento do card semanal
- [x] Modo foco ativo: marcar dia verde somente com foco elegivel (>= 5 min) na acao.
- [x] Modo foco desativado: marcar dia verde com confirmacao manual de acao no dia.
- [x] Garantir timezone local consistente no fechamento/virada de dia.

7. Etapa 8.7 - Preparacao da feature mensal (sem UI final ainda)
- [x] 8.7.1 - Decisao de UX mensal (fechar direcao do produto)
  - Direcao recomendada: visao mensal por meta (na tela de detalhe da meta), sem aba global nova.
  - Alternativa (mais custosa): aba mensal global com filtros por meta/acao para evitar poluicao visual.
- [x] 8.7.2 - Contrato de dominio para historico mensal por acao
  - Generalizar calculo diario atual (cinza/verde/vermelho) para intervalo arbitrario de dias.
  - Manter regra unica por modo:
    - foco ativo: concluido apenas com foco elegivel (>= 5 min);
    - checklist: concluido por confirmacao manual/sinalizacao diaria.
- [x] 8.7.3 - Provider/use-case mensal por meta
  - Criar leitura mensal por `goalId` + `mes/ano`, reutilizando `focusSessions` e `actionDayConfirmations`.
  - Garantir consistencia de timezone local no fechamento do dia.
- [x] 8.7.4 - Estrategia de UI mensal sem quebrar o fluxo atual
  - Inserir modo `Mes` no card semanal da tela de detalhe da meta (ex: toggle `Semana | Mes`).
  - Exibir grade mensal por acao com legenda de estado (`pendente`, `feito`, `nao feito`).
- [x] 8.7.5 - Limites de UX para manter legibilidade em mobile
  - Definir limite inicial de exibicao (ex: ate 3-5 acoes visiveis com scroll interno).
  - Definir comportamento para meses com 28-31 dias sem overflow horizontal.
- [x] 8.7.6 - Cenarios de teste da visao mensal
  - [x] Domain/presentation tests para meses com 28/30/31 dias, virada de mes e timezone (inclui provider mensal por `goalId + mes/ano`).
  - [x] Widget tests para alternancia `Semana | Mes`, foco on/off e estado vazio.
- [ ] 8.7.7 - Backlog opcional (adiado/cancelado neste ciclo)
  - Avaliar uma aba mensal global de insights (resumo agregado), sem listar todas as acoes por padrao.

8. Etapa 8.8 - Testes e regressao
- [x] Widget test: toggle de foco no Drawer altera UI e persiste estado.
- [x] Widget tests: fluxo checklist com swipe + confirmacao diaria.
- [x] Widget tests: card semanal em ambos os modos (foco on/off).
- [x] Regressao: modo foco ativo continua funcionando sem mudanca de regra.
- [x] Revalidar `flutter test -r compact` e perfis `smoke/regression/full`.

9. Etapa 8.9 - Refinamentos futuros do bloco de metricas (backlog)
- [x] Refinar UX da Home no modo checklist para ocupar o espaco da metrica de horas com feedback contextual do modo foco desativado.
- [x] Revisar microcopy do bloco de metricas para deixar claro quando o usuario esta no modo checklist vs modo foco.
- [x] No modo checklist, exibir apenas chips de `streak` + `acoes concluidas hoje`.

10. Etapa 8.10 - Pivot do card semanal (meta -> acoes diarias por meta)
- [x] Reposicionar o card semanal para dentro da tela de detalhe da meta (remover dependência da Home para essa visualizacao).
- [x] Estruturar grade semanal por acao:
  - cabecalho fixo `Seg | Ter | Qua | Qui | Sex | Sab | Dom`;
  - cada linha representa uma acao da meta.
- [x] Definir estados visuais por celula (acao x dia):
  - cinza: dia em aberto;
  - verde: acao concluida no dia;
  - vermelho: dia encerrado sem conclusao.

11. Etapa 8.11 - Reabertura diaria automatica de acoes
- [x] Ajustar regra de dominio para reabrir acao automaticamente no dia seguinte.
- [x] Garantir que a reabertura diaria nao quebre historico da semana.
- [x] Manter concluido permanente apenas para o estado final da meta (nao da acao diaria).

12. Etapa 8.12 - Convivencia com modo foco e modo checklist
- [x] Modo foco ativo: dia verde somente com foco elegivel (>= 5 min) para a acao.
- [x] Modo foco desativado: dia verde por confirmacao manual da acao no dia.
- [x] Garantir consistencia de virada de dia em timezone local para ambas as regras.

13. Etapa 8.13 - Home simplificada apos pivot semanal
- [x] Remover o card semanal da Home.
- [x] Manter Home orientada a resumo (metas prioritarias + lista de metas) sem duplicacao do quadro semanal.
- [x] Ajustar espacamentos/titulos para manter hierarquia visual limpa.

14. Etapa 8.14 - Testes de regressao do fluxo semanal por acao
- [x] Domain tests: estados cinza/verde/vermelho por dia e por acao.
- [x] Widget tests: grade semanal na tela da meta com multiplas acoes.
- [x] Widget tests: reabertura diaria automatica no dia seguinte.
- [x] Regressao: fluxo atual de foco/checklist segue funcional sem efeitos colaterais.

### Sprint 9 - Release MVP
- Testes finais
- Revisão
- Build release
- Roadmap V2

## Decisões técnicas (12/03/2026)

- Navegação de edição/ações de metas refatorada para `goalId` em path params, removendo dependência de `state.extra`.
- Estado de onboarding movido para storage local com Hive + `ChangeNotifier` (`refreshListenable` no `GoRouter`).
- Persistência local tipada com `Map<String, dynamic>` em mappers e repositório.
- Home ajustada para considerar apenas metas ativas no topo e no progresso médio.
- Fluxo de acoes estabilizado com atualizacao explicita da Home apos mutações.
- Validação centralizada por `TitleValidator` com limite de caracteres também no input (`LengthLimitingTextInputFormatter`).
- Tratamento de erro de UI padronizado com `SnackBar` em criacao/edicao de metas e acoes.
- Cobertura de testes ampliada para:
- usuário com historico longo (10 metas concluidas + 5 ativas)
- CRUD de acoes,
- input extremo (titulo e descricao longos),
- estabilidade no retorno da tela de acoes (10 ciclos sem estado de retry).

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
  - `completedAt` e recalculo de progresso seguem pelo fluxo de atualizacao da acao;
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
## 20. Visão de Evolucao (Pos-MVP)

Possíveis evoluções:
- Sincronização na nuvem
- Conta do usuário
- Metas compartilhadas
- Gamificação
- IA sugerindo planos
- Análise de hábitos

## 21. Filosofia do Projeto

### 1. Entregar valor rapido
Pequenas releases funcionais.

### 2. Simplicidade acima de complexidade
O MVP deve ser simples.

### 3. Aprendizado através da construção
Evoluir como desenvolvedor enquanto constroi um produto real.

## 22. Regra Final do Projeto

Se uma decisão aumentar muito a complexidade do projeto sem aumentar o valor para o usuario, ela deve ser evitada.



### Atualizacao tecnica (27/03/2026 - Perfis de testes)

- Adicionado runner de testes em `scripts/run_tests.ps1` com preflight para reduzir intermitencia no Windows.
- Preflight agora encerra processos `flutter/dart` pendurados e limpa lockfiles/artefatos de teste antes da execucao.
- Perfis disponiveis para execucao incremental:
  - `smoke` (rapido),
  - `regression` (intermediario),
  - `full` (suite completa).
- Testes agora classificados com tags reais (`smoke`, `regression`, `full`) para execucao seletiva em CI/local (`flutter test --tags ...`).

### Atualizacao tecnica (30/03/2026 - Sprint 8.3)

- `GoalActionsPage` agora reage em tempo real ao toggle `focusModeEnabled`:
  - com foco ativo: fluxo atual permanece (selecao de acao + CTA `Iniciar foco`);
  - com foco desativado: selecao/CTA de foco ficam ocultos.
- Fluxo checklist na tela de acoes:
  - swipe de concluir/reabrir mantido;
  - bloqueio `Sem tempo gasto na ação.` passa a valer apenas quando foco estiver ativo.
- Adicionado botao de confirmacao diaria por acao (`Confirmar`) no modo checklist.
- Confirmacao diaria com idempotencia por dia/acao e persistencia local.
- Cobertura de testes adicionada/validada:
  - ocultacao dos controles de foco quando desativado;
  - confirmacao diaria visivel no modo checklist;
  - conclusao por swipe sem tempo de foco quando modo foco estiver desativado.
- Validacoes executadas:
  - `flutter test test/widgets/focus_widget_test.dart -r compact --concurrency=1`
  - `flutter test test/widgets/home_and_settings_widget_test.dart -r compact --concurrency=1`
  - `powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile smoke -Expanded`

### Atualizacao tecnica (30/03/2026 - Sprint 8.4)

- Persistencia de confirmacao diaria implementada no contrato de repositorio (`GoalsRepository`), com:
  - listagem por `goalId`, `actionId` e `day`;
  - salvar e excluir confirmacoes.
- `LocalGoalsRepository` atualizado com box dedicada (`action_day_confirmations_box`) e limpeza de confirmacoes ao excluir meta/acao.
- `FakeInMemoryGoalsRepository` atualizado para suportar confirmacao diaria persistida nos testes.
- `GoalActionsController` passou a registrar confirmacao diaria com idempotencia por dia/acao.
- `GoalActionsPage` passou a ler confirmacoes persistidas e refletir estado `Confirmada hoje` mesmo apos reabrir a tela.
- Compatibilidade de dados legados coberta com novo teste em `mapper_compatibility_test.dart`.

### Atualizacao tecnica (30/03/2026 - Sprint 8.6)

- Regra semanal consolidada inicialmente no dashboard com a semana corrente (`Seg` -> `Dom`) em vez de janela rolante de 7 dias.
- Preenchimento do card semanal confirmado por modo de uso:
  - foco ativo: verde apenas com foco elegivel (>= 5 min) na meta;
  - foco desativado: verde apenas com confirmacao manual no dia.
- Consistencia de virada de dia reforcada por normalizacao em dia local (`toLocal` + `dateOnly`) no calculo diario.
- Testes adicionados/validados:
  - `goal_daily_completion_calculator_test.dart` ganhou cenarios com timestamps persistidos em UTC para validacao por dia local;
  - `dashboard_and_goal_detail_widget_test.dart` revalidado com os ajustes de layout/scroll da Home.

### Atualizacao tecnica (30/03/2026 - Sprint 8.10 a 8.13)

- Card semanal pivotado da Home para a tela de detalhe da meta (`GoalActionsPage`), mantendo a Home focada em resumo.
- Quadro semanal agora e por acao (linhas de acoes da meta) com estados:
  - `pending` (cinza) para dia atual/futuro sem conclusao;
  - `done` (verde) para acao concluida no dia;
  - `missed` (vermelho) para dia passado sem conclusao.
- Reabertura diaria automatica implementada:
  - ao abrir/recarregar a tela da meta, acoes concluidas em dia anterior voltam para pendentes;
  - objetivo: manter o ciclo diario da acao sem apagar o historico semanal.
- Modo checklist refinado:
  - ao concluir por swipe com modo foco desativado, a confirmacao diaria e registrada automaticamente (idempotente no dia), garantindo celula verde no quadro semanal.
- Limpeza tecnica da Home:
  - removido bloco semanal legado nao utilizado de `dashboard_page.dart`.
- Cobertura e validacao:
  - novo teste de widget para reabertura diaria automatica no dia seguinte;
  - teste de widget do fluxo checklist atualizado para validar persistencia de confirmacao diaria apos swipe;
  - suites revalidadas: 
    - `test/widgets/focus_widget_test.dart`
    - `test/widgets/dashboard_and_goal_detail_widget_test.dart`
    - `test/widgets/home_and_settings_widget_test.dart`
    - `test/widgets/priorities_and_layout_widget_test.dart`
  - `dart analyze lib test` executado sem warnings novos de compilacao (apenas infos/deprecations ja conhecidas).

### Atualizacao tecnica (30/03/2026 - Sprint 8.14)

- Regra semanal por acao extraida para dominio em `ActionWeeklyStatusCalculator`:
  - fonte unica para estados `pending` (cinza), `done` (verde) e `missed` (vermelho).
- Tela da meta passou a reutilizar o calculator de dominio no quadro semanal, reduzindo duplicacao de regra na UI.
- Cobertura de dominio adicionada em `goal_daily_completion_calculator_test.dart` para:
  - dia concluido via foco elegivel (`>= 5 min`);
  - dia atual pendente;
  - dia passado sem conclusao (missed);
  - checklist com confirmacao manual;
  - checklist com conclusao da acao no proprio dia;
  - geracao semanal completa de segunda a domingo.
- Regressao validada:
  - `test/features/goals/domain/goal_daily_completion_calculator_test.dart`
  - `test/widgets/dashboard_and_goal_detail_widget_test.dart`
  - `test/widgets/focus_widget_test.dart`
  - `dart analyze lib test`

### Atualizacao tecnica (30/03/2026 - Sprint 8.9)

- Bloco de metricas da Home ajustado para respeitar o modo de uso:
  - modo foco ativo: `streak` + horas investidas;
  - modo checklist: `streak` + total de acoes confirmadas/concluidas no dia.
- Nova leitura diaria adicionada via provider dedicado (`dailyCompletedActionsProvider`) com contagem unica por `actionId` no dia local.
- Invalidacoes adicionadas apos mutacoes relevantes (confirmar acao, excluir acao e excluir meta) para atualizar o chip em tempo real.
- Cobertura de widget test reforcada para:
  - ocultar chip de horas no modo checklist;
  - exibir `0 acoes hoje` no estado inicial;
  - atualizar para `1 acao hoje` apos confirmacao diaria.
- Validacoes executadas:
  - `flutter test test/widgets/home_and_settings_widget_test.dart -r compact --concurrency=1`
  - `flutter test test/widgets/dashboard_and_goal_detail_widget_test.dart -r compact --concurrency=1`
  - `flutter test test/widgets/focus_widget_test.dart -r compact --concurrency=1`

### Atualizacao tecnica (30/03/2026 - Sprint 8.8)

- Cobertura do card semanal consolidada com widget test em ambos os modos:
  - checklist (`focusModeEnabled = false`) por confirmacao diaria;
  - foco ativo (`focusModeEnabled = true`) por sessao elegivel (`>= 5 min`).
- Revalidacao dos perfis automatizados concluida com sucesso:
  - `powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile smoke -Expanded`
  - `powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile regression -Expanded`
  - `powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1 -Profile full -Expanded`
- Durante a revalidacao do perfil `full`, houve divergencia de golden na tela de detalhe da meta; baseline atualizado para refletir a UI atual:
  - `flutter test test/ui_golden_test.dart --update-goldens -r compact --concurrency=1`

### Atualizacao tecnica (30/03/2026 - Sprint 8.7)

- Base tecnica mensal implementada sem alterar o fluxo principal atual:
  - `ActionWeeklyStatusCalculator` agora suporta intervalo arbitrario de dias e mes completo (`monthDays`, `buildMonthStatuses`, `buildStatusesForDays`).
  - novo contrato de dominio para leitura mensal por meta:
    - `GoalMonthlyHistory`
    - `GoalMonthlyHistoryRow`
    - `GoalMonthlyHistoryArgs`
  - novo provider/use-case:
    - `goalMonthlyHistoryProvider` em `goal_actions_controller.dart` (leitura por `goalId + mes/ano`).
- UI mensal 8.7.4 concluida na tela de detalhe da meta:
  - card semanal com toggle `Semana | Mês`;
  - modo `Mês` com grade mensal por ação;
  - legenda de estado (`Pendente`, `Feito`, `Não feito`) no rodape do card.
- Cobertura adicionada:
  - testes de dominio para calendario mensal em `goal_daily_completion_calculator_test.dart`;
  - widget test de alternancia e grade mensal em `dashboard_and_goal_detail_widget_test.dart`;
  - cenarios mensais (checklist/foco) em `focus_streak_persistence_test.dart`.

### Atualizacao tecnica (31/03/2026 - Sprint 8.7.5)

- Limites de UX da visao mensal aplicados no card da meta:
  - exibicao mensal com limite de 3-5 linhas de acoes visiveis (adaptado por altura de tela);
  - scroll interno vertical quando houver mais acoes que o limite visivel;
  - grade mensal mantida sem overflow horizontal para meses de 28/30/31 dias.
- Cobertura de widget test adicionada:
  - validacao de scroll interno no modo `Mês` em tela pequena.
  - validacao de estado vazio no modo `Mês` (meta sem acoes).
- Etapa 8.7.7 mantida como adiada/cancelada neste ciclo.




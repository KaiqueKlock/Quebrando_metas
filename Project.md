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
- Status: Em andamento (atualizado em 13/03/2026)

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

- Refinar UI
  - [x] Centralizar botao `Nova Meta` no navigator, removendo o texto do botao
- Refinamento de Theme
  - [x] Adicionar Drawer na AppBar para configuracoes de aparencia (Dashboard e Suas Metas)
  - [x] Adicionar alternancia de tema (`Claro`/`Escuro`) com icone unico (`sol`/`lua`)
  - [x] Adicionar menu recolhivel para escolha de cor principal
  - [x] Persistir preferencias de tema localmente

- Sugestoes de melhoria (proximos passos)
  - [x] Revisar contraste e acessibilidade (WCAG) das cores selecionaveis
  - [x] Refinar espacamento/altura de cards para melhor leitura em telas menores
  - [ ] Adicionar micro-animacoes leves na troca de abas e prioridades


### Sprint 5 - Pomodoro Feature 



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





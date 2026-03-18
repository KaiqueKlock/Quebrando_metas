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

### Nova Feature Planejada - Modo Foco (Sprint 5)

O proximo passo do produto e integrar um fluxo de **Modo Foco** (inspirado em Pomodoro) diretamente nas acoes das metas.

## Objetivo

Permitir que o usuario execute uma acao com timer e registrar tempo real de dedicacao, criando historico de esforco e consistencia.

## Fluxo esperado

1. O usuario seleciona uma acao e inicia foco.
2. Escolhe a duracao (15, 25 ou 45 minutos).
3. Durante foco, visualiza:
- nome da meta
- nome da acao
- tempo restante
- botao para cancelar
4. Ao terminar, o app:
- registra a sessao de foco
- incrementa tempo acumulado da acao
- atualiza tempo total agregado da meta
5. A acao **nao** e concluida automaticamente. Conclusao continua manual pelo usuario.

## Regra oficial de streak

- O streak conta **somente** quando o usuario inicia foco em uma acao.
- Conclusao manual da acao nao incrementa streak.
- Se passar 1 dia sem iniciar foco, streak zera.

## Resultado esperado da feature

- Progresso mais visivel (tempo por acao e por meta)
- Melhor consistencia de execucao diaria (streak)
- Fluxo natural de uso, sem excesso de cliques

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
# Decisões Técnicas

Decisões atuais de arquitetura e implementação (alinhadas ao `Project.md`):

- Navegação de metas e ações por `goalId` em path params, sem depender de `state.extra`.
- Estado de onboarding persistido localmente com Hive e aplicado no redirect via `refreshListenable` do GoRouter.
- Persistência local tipada com `Map<String, dynamic>` na camada de dados.
- Progresso de meta derivado de ações concluídas (`completedActions / totalActions`), sem edição manual de progresso.
- Home com foco em metas ativas (contagem e progresso médio considerando apenas metas não concluídas).
- Validação centralizada de título com `TitleValidator`, incluindo bloqueio de entrada com `LengthLimitingTextInputFormatter`.
- Tratamento de erros de UI com feedback visual (`SnackBar`) em criação/edição/exclusão.
- Cobertura de testes ampliada para cenários de uso real (histórico longo, CRUD de ações, input extremo e estabilidade de navegação).

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






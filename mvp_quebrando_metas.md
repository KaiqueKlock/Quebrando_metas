# GDD / MVP - Quebrando Metas (Alinhado)

## 1. Visao Geral

**Nome do projeto:** Quebrando Metas  
**Tipo:** Aplicativo mobile (Android/iOS)  
**Categoria:** Produtividade pessoal / Metas / Habitos

**Proposta central:** ajudar usuarios a transformar objetivos grandes em etapas menores e acionaveis, com progresso visual e clareza sobre o proximo passo.

## 2. Problema que o App Resolve

Usuarios frequentemente:
- Criam metas grandes e abstratas
- Nao sabem por onde comecar
- Perdem motivacao por falta de progresso visivel

O problema principal e falta de estrutura para executar a meta no dia a dia.

## 3. Solucao Proposta (MVP)

Modelo do MVP:

```text
Meta (Goal)
  -> Etapas (Step)
```

No MVP, o foco e manter simplicidade operacional: metas e etapas, sem camada adicional de "acoes".

## 4. Publico-Alvo

- Pessoas com objetivos pessoais (saude, estudo, carreira)
- Usuarios iniciantes em produtividade
- Pessoas que precisam de clareza para quebrar objetivos em passos menores

## 5. Objetivo do MVP

Validar se:
- Usuarios conseguem criar metas e etapas com facilidade
- O progresso da meta fica claro visualmente
- O fluxo principal e simples e motivador

## 6. Escopo do MVP

### 6.1 Funcionalidades incluidas

#### Metas
- Criar meta
- Editar meta
- Excluir meta
- Listar metas ativas
- Visualizar progresso da meta

#### Etapas
- Adicionar etapas em uma meta
- Editar etapas
- Excluir etapas
- Marcar etapas como concluidas

#### Progresso
- Progresso da meta baseado em etapas concluidas
- Indicador visual simples (barra e/ou percentual)

### 6.2 Fora do escopo (MVP)

- Login / conta
- Sincronizacao em nuvem
- Gamificacao
- Ranking / social
- Notificacoes inteligentes
- Sugestao automatica com IA
- Modelo de "acoes" com frequencia e contador

## 7. Modelo de Dados (MVP)

### Goal

Campos:
- `id`
- `title`
- `description`
- `createdAt`
- `progress`

### Step

Campos:
- `id`
- `goalId`
- `title`
- `isCompleted`
- `createdAt`

### Regra de progresso

```text
progress = etapas_concluidas / total_de_etapas
```

Exemplo:
- 4 etapas
- 2 concluidas
- progresso = 50%

## 8. Fluxo Principal do Usuario

1. Usuario abre o app
2. Visualiza lista de metas
3. Cria uma meta
4. Adiciona etapas
5. Marca etapas como concluidas
6. Visualiza o progresso atualizado

Este e o core loop do produto no MVP.

## 9. Telas do MVP

### 9.1 Home (Metas)
- Lista de metas
- Progresso por meta
- Acao para criar meta

### 9.2 Criar/Editar Meta
- Campo titulo
- Campo descricao
- Acao salvar

### 9.3 Detalhe da Meta
- Nome da meta
- Progresso geral
- Lista de etapas
- Acao para adicionar etapa

### 9.4 Criar/Editar Etapa
- Campo titulo
- Acao salvar
- Marcacao de concluida

## 10. Regras de Negocio

- Uma meta so avanca quando etapas sao concluidas
- Progresso e calculado automaticamente
- O usuario nao ajusta progresso manualmente
- Etapas devem ser simples e executaveis

## 11. Stack Tecnologica (Definida)

- Flutter
- Dart
- Riverpod (estado)
- GoRouter (navegacao)
- Hive ou Isar (persistencia local)
- `flutter_test`
- `integration_test`

## 12. Diretrizes de Arquitetura

- Simplicidade (evitar overengineering)
- Separacao de responsabilidades
- Codigo organizado por feature
- Widgets pequenos e focados

## 13. Estrategia de Testes

### Unit tests
- Calculo de progresso
- Validacoes de Goal e Step

### Widget tests
- Lista de metas
- Formulario de criacao
- Indicador de progresso

### Integration tests
- Criar meta
- Adicionar etapa
- Concluir etapa
- Verificar progresso atualizado

## 14. Criterios de Pronto

Uma feature e considerada pronta quando:
- Funciona corretamente
- Passa na analise estatica
- Possui testes adequados
- Segue o padrao do projeto
- Nao adiciona complexidade desnecessaria

## 15. Evolucao Pos-MVP (Backlog)

Possiveis evolucoes:
- Sincronizacao em nuvem
- Conta de usuario
- Metas compartilhadas
- Gamificacao
- IA sugerindo planos
- Camada de "acoes" dentro das etapas

## 16. Decisoes de Alinhamento com PROJECT.md

- O documento canonico de engenharia e produto e o `Project.md`.
- O MVP oficial usa apenas `Goal` e `Step`.
- O modelo `Meta -> Etapas -> Acoes` foi movido para pos-MVP.
- A stack oficial e Riverpod + GoRouter + Hive/Isar.

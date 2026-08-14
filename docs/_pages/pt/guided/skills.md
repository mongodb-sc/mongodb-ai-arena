---
title: "Potencialize o Cline com Habilidades"
permalink: /pt/guided/skills/
layout: single
classes: wide
lang: pt
---

## 🧠 De Assistente Genérico a Especialista em MongoDB

De fábrica, o Cline é um excelente assistente de codificação de propósito geral. As **Habilidades do Cline** são conjuntos de instruções elaborados pelo MongoDB que o tornam um especialista de domínio—cobrindo design de esquemas, otimização de consultas, busca e muito mais. Já vêm pré-instaladas no seu workspace.

---

### 🔍 Passo 1: Encontre suas Habilidades

O painel de Habilidades está atrás do **ícone de balança ⚖** na área de entrada de chat do Cline (não em Configurações).

1. Clique no ícone do **Cline** na barra lateral do VSCode para abrir o painel de chat.
2. Na entrada de chat, clique no **ícone de balança ⚖**.
3. Você deve ver uma lista de habilidades do MongoDB, incluindo:
   - `mongodb-schema-design`
   - `mongodb-natural-language-querying`
   - `mongodb-query-optimizer`
   - `mongodb-search-and-ai`
   - `mongodb-mcp-setup`
   - `mongodb-connection`
   - `atlas-stream-processing`

**⚠️ Nota:** Se você não ver nenhuma habilidade, recarregue a janela: `☰ > View > Command Palette… > Developer: Reload Window`.

---

### 🤖 Passo 2: Teste a Habilidade de Design de Esquemas

**📋 Prompt:** Inicie um novo chat no Cline e cole isso:

> Use a habilidade **mongodb-schema-design**. Estou migrando de um esquema Postgres onde `bookings`, `listings`, `hosts`, `addresses` e `reviews` são cinco tabelas unidas por chaves estrangeiras. Me atrai criar cinco coleções no MongoDB com referências `ObjectId` que imitam as chaves estrangeiras. Por que isso é um erro e o que devo fazer em vez disso? Seja específico sobre quais tabelas mesclar e quais manter separadas, e por quê.

---

### 🎯 Passo 3: Revise a Resposta

A resposta potencializada por habilidades deve fazer referência a conceitos específicos do MongoDB por nome. Procure por:

- **Anti-padrões** apontados explicitamente (p. ex., `excessive-lookups`, `unnecessary-collections`)
- **Padrões de design** nomeados (p. ex., `extended-reference`, `bucket`, `computed`)
- **O framework embed-vs-reference** aplicado por relação (1:1, 1:poucos, 1:muitos, M:N)
- Uma recomendação concreta, por exemplo:
  - **Incorpore** `address` em `listings` (1:1, sempre acessados juntos)
  - **Referência estendida** para `host` dentro de `listings` (cache `name` e `picture_url`, mantenha o documento de host completo separado)
  - **Referência** para `reviews` (ilimitado, pode crescer além do limite de 16MB do documento)
  - **Referência** para `bookings` (ciclo de vida independente, consultado separadamente)
- O princípio norteador citado: *"Os dados que são acessados juntos devem ser armazenados juntos."*

---

### 💡 A Conclusão

**Cada seção principal desta Arena tem uma habilidade correspondente:**
- 📊 Agregações e consultas lentas → `mongodb-query-optimizer`
- 🔎 Atlas Search e 🧠 Vector Search → `mongodb-search-and-ai`
- ✏️ Escrever consultas do zero → `mongodb-natural-language-querying`

Recorra ao **ícone de balança ⚖** cada vez que começar uma nova seção. Você obterá respostas ajustadas para MongoDB, não suposições genéricas com sabor SQL.

---

### 📚 Aprenda Mais

- [MongoDB Agent Skills no GitHub](https://github.com/mongodb/agent-skills)
- [Documentação de Habilidades do Cline](https://docs.cline.bot/features/skills)

{% include simple_next_nav.html %}

---
title: "Atlas Vector Search: Dica sobre Índices"
permalink: /pt/vector-search/index-hint/
layout: single
classes: wide
categories: [vector-search, vector-search-index]
lang: pt
---

## 🚀 Dica: Índices de Atlas Vector Search—Desbloqueie o Poder Semântico

Quer pesquisa semântica com IA no seu aplicativo? Os índices de Atlas Vector Search permitem pesquisar por significado, não apenas palavras-chave!
Gere embeddings automaticamente a partir de seus campos de texto e filtre resultados para uma descoberta mais inteligente e relevante.

- 🛠️ [Gerenciar Índice](https://www.mongodb.com/docs/atlas/atlas-search/manage-indexes/)  

- 🤖 **Embeddings Automatizados**: Deixe o MongoDB lidar com a conversão de texto para vetor automaticamente.  
  [Documentação de Embedding Automatizado](https://www.mongodb.com/docs/atlas/atlas-vector-search/automated-embedding/)

### ✨ Exemplo: Definição de Índice de Vector Search

```json
{
  "fields": [
    {
      "type": "text",
      "path": "description",
      "model": "voyage-3-large"
    },
    {
      "type": "filter",
      "path": "property_type"
    }
  ]
}
```

💡 Use campos vetoriais para pesquisa semântica e campos de filtro para restringir os resultados por critérios específicos.

{% include simple_next_nav.html %}

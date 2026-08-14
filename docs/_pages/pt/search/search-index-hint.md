---
title: "Atlas Search: Dica sobre Índices"
permalink: /pt/search/index-hint/
layout: single
classes: wide
categories: [search, search-index]
lang: pt
---

## 🚀 Dica: Índices de Atlas Search—Libere o Poder

Quer pesquisa de texto completo ultrarrápida em seu aplicativo? Os índices do Atlas Search são sua arma secreta!  
Crie experiências de pesquisa personalizadas com analisadores flexíveis, mapeamentos de campos inteligentes e facetamento poderoso.

- 🛠️ [Gerenciar Índice](https://www.mongodb.com/docs/atlas/atlas-search/manage-indexes/)  
- 🧬 [Definir Mapeamentos de Campos](https://www.mongodb.com/docs/atlas/atlas-search/define-field-mappings/)

### ✨ Exemplo: Definição de Índice de Próximo Nível

```json
{
  "analyzer": "lucene.english",
  "searchAnalyzer": "lucene.english",
  "mappings": {
    "dynamic": false,
    "fields": {
      "amenities": { "type": "token" },
      "beds": { "type": "number" },
      "name": {
        "analyzer": "lucene.english",
        "foldDiacritics": false,
        "maxGrams": 7,
        "minGrams": 3,
        "type": "autocomplete"
      },
      "property_type": { "type": "token" }
    }
  }
}
```

💡 Combine tipos de campos, analisadores e facetas para criar uma pesquisa que pareça mágica!

{% include simple_next_nav.html %}

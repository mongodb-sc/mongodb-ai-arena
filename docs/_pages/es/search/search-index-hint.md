---
title: "Atlas Search: Pista sobre Índices"
permalink: /es/search/index-hint/
layout: single
classes: wide
categories: [search, search-index]
lang: es
---

## 🚀 Pista: Índices de Atlas Search—Desata el Poder

¿Quieres búsqueda de texto completo ultrarrápida en tu aplicación? ¡Los índices de Atlas Search son tu arma secreta!  
Crea experiencias de búsqueda personalizadas con analizadores flexibles, mapeos de campos inteligentes y facetado poderoso.

- 🛠️ [Administrar Índice](https://www.mongodb.com/docs/atlas/atlas-search/manage-indexes/)  
- 🧬 [Definir Mapeos de Campos](https://www.mongodb.com/docs/atlas/atlas-search/define-field-mappings/)

### ✨ Ejemplo: Definición de Índice de Siguiente Nivel

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

💡 ¡Combina tipos de campos, analizadores y facetas para crear una búsqueda que parezca mágica!

{% include simple_next_nav.html %}

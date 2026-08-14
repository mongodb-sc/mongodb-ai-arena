---
title: "Atlas Vector Search: Pista sobre Índices"
permalink: /es/vector-search/index-hint/
layout: single
classes: wide
categories: [vector-search, vector-search-index]
lang: es
---

## 🚀 Pista: Índices de Atlas Vector Search—Desbloquea el Poder Semántico

¿Quieres búsqueda semántica potenciada por IA en tu aplicación? ¡Los índices de Atlas Vector Search te permiten buscar por significado, no solo por palabras clave!  
Incrusta automáticamente tus campos de texto y filtra resultados para un descubrimiento más inteligente y relevante.

- 🛠️ [Administrar Índice](https://www.mongodb.com/docs/atlas/atlas-search/manage-indexes/)  

- 🤖 **Embeddings Automatizados**: Deja que MongoDB maneje la conversión de texto a vector automáticamente.  
  [Documentación de Embedding Automatizado](https://www.mongodb.com/docs/atlas/atlas-vector-search/automated-embedding/)

### ✨ Ejemplo: Definición de Índice de Vector Search

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

💡 Usa campos vectoriales para búsqueda semántica y campos de filtro para reducir los resultados por criterios específicos.

{% include simple_next_nav.html %}

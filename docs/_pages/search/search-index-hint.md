---
title: "Atlas Search: Indexes Hint"
permalink: /search/index-hint/
layout: single
classes: wide
categories: [search, search-index]
---

## 🚀 Hint: Atlas Search Indexes—Unleash the Power

Want lightning-fast, full-text search in your app? Atlas Search indexes are your secret weapon!  
Craft custom search experiences with flexible analyzers, smart field mappings, and powerful faceting.

- 🛠️ [Manage Index](https://www.mongodb.com/docs/atlas/atlas-search/manage-indexes/)  
- 🧬 [Define Fields Mapping](https://www.mongodb.com/docs/atlas/atlas-search/define-field-mappings/)

### ✨ Example: Next-Level Index Definition

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

💡 Mix and match field types, analyzers, and facets to create search that feels magical!

{% include simple_next_nav.html %}

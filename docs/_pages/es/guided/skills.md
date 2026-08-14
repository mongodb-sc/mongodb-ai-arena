---
title: "Potencia Cline con Habilidades"
permalink: /es/guided/skills/
layout: single
classes: wide
lang: es
---

## 🧠 De Asistente Genérico a Experto en MongoDB

De fábrica, Cline es un excelente asistente de codificación de propósito general. Las **Habilidades de Cline** son conjuntos de instrucciones elaborados por MongoDB que lo convierten en un experto de dominio—cubriendo diseño de esquemas, optimización de consultas, búsqueda y más. Ya vienen preinstaladas en tu workspace.

---

### 🔍 Paso 1: Encuentra tus Habilidades

El panel de Habilidades se encuentra detrás del **ícono de balanza ⚖** en el área de entrada de chat de Cline (no en Configuración).

1. Haz clic en el ícono de **Cline** en la barra lateral de VSCode para abrir el panel de chat.
2. En la entrada de chat, haz clic en el **ícono de balanza ⚖**.
3. Deberías ver una lista de habilidades de MongoDB, incluyendo:
   - `mongodb-schema-design`
   - `mongodb-natural-language-querying`
   - `mongodb-query-optimizer`
   - `mongodb-search-and-ai`
   - `mongodb-mcp-setup`
   - `mongodb-connection`
   - `atlas-stream-processing`

**⚠️ Nota:** Si no ves ninguna habilidad, recarga la ventana: `☰ > View > Command Palette… > Developer: Reload Window`.

---

### 🤖 Paso 2: Prueba la Habilidad de Diseño de Esquemas

**📋 Prompt:** Inicia un nuevo chat en Cline y pega esto:

> Usa la habilidad **mongodb-schema-design**. Estoy migrando de un esquema Postgres donde `bookings`, `listings`, `hosts`, `addresses` y `reviews` son cinco tablas unidas por claves foráneas. Me tienta crear cinco colecciones en MongoDB con referencias `ObjectId` que imitan las claves foráneas. ¿Por qué es eso un error y qué debería hacer en su lugar? Sé específico sobre qué tablas fusionar y cuáles mantener separadas, y por qué.

---

### 🎯 Paso 3: Revisa la Respuesta

La respuesta potenciada por habilidades debe hacer referencia a conceptos específicos de MongoDB por nombre. Busca:

- **Anti-patrones** señalados explícitamente (p. ej., `excessive-lookups`, `unnecessary-collections`)
- **Patrones de diseño** nombrados (p. ej., `extended-reference`, `bucket`, `computed`)
- **El marco embed-vs-reference** aplicado por relación (1:1, 1:pocos, 1:muchos, M:N)
- Una recomendación concreta, por ejemplo:
  - **Incrusta** `address` en `listings` (1:1, siempre accedidos juntos)
  - **Referencia extendida** para `host` dentro de `listings` (cache `name` y `picture_url`, mantén el documento de host completo separado)
  - **Referencia** para `reviews` (ilimitado, puede crecer más allá del límite de 16MB del documento)
  - **Referencia** para `bookings` (ciclo de vida independiente, consultado por separado)
- El principio guía citado: *"Los datos que se acceden juntos deben almacenarse juntos."*

---

### 💡 La Conclusión

**Cada sección principal de esta Arena tiene una habilidad correspondiente:**
- 📊 Agregaciones y consultas lentas → `mongodb-query-optimizer`
- 🔎 Atlas Search y 🧠 Vector Search → `mongodb-search-and-ai`
- ✏️ Escribir consultas desde cero → `mongodb-natural-language-querying`

Recurre al **ícono de balanza ⚖** cada vez que comiences una nueva sección. Obtendrás respuestas ajustadas para MongoDB, no suposiciones genéricas con sabor SQL.

---

### 📚 Aprende Más

- [MongoDB Agent Skills en GitHub](https://github.com/mongodb/agent-skills)
- [Documentación de Habilidades de Cline](https://docs.cline.bot/features/skills)

{% include simple_next_nav.html %}

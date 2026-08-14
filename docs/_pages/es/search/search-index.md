---
title: "Atlas Search: Índices"
permalink: /es/search/index/
layout: single
classes: wide
categories: [search]
lang: es
---

## 🚀 Objetivo: Potencia la Búsqueda con Índices de Atlas Search

Tu negocio quiere deleitar a los usuarios con resultados de búsqueda instantáneos y relevantes y sugerencias inteligentes. Pero antes de poder ofrecer esa experiencia mágica, necesitas sentar las bases: un poderoso índice de Atlas Search. Como ingeniero backend, estás preparando el escenario para el autocompletado, la navegación facetada y el descubrimiento ultrarrápido.

En este ejercicio, diseñarás y construirás un índice de Atlas Search personalizado—desbloqueando todo el potencial de tus datos.

---

### 🧩 Ejercicio: Construye tu Índice de Búsqueda

Crea tu índice con estas especificaciones:

1. **Configuración Básica**
   - **Nombre:** `search_index`
   - **Analizador:** `lucene.english`
   - **Mapeo Dinámico:** Desactivado

2. **Mapeos de Campos**
   - **name** (para autocompletado)
     - Tipo: `autocomplete`
     - Analizador: `lucene.english`
     - Tokenización: `edgeGram`
     - Gramo mín: `3`
     - Gramo máx: `7`
     - Plegado de diacríticos: `false`
   
   - **amenities** (para filtrado)
     - `token` (valor: `none`)

   - **property_type** (para filtrado)
     - `token` (valor: `none`)

   - **beds** (para filtrado numérico)
     - `number`

---

### 🛠️ Cómo Completar este Ejercicio

Elige tu herramienta favorita e indexa:
- Interfaz web de **MongoDB Atlas**
- **MongoDB Compass**
- **Extensión de MongoDB** con el MongoDB Playground proporcionado

#### 💻 **¿Usas VS Code?**
- Sugerimos usar la función Playground para una experiencia rápida e interactiva.
- En VSCode Online, localiza y abre el archivo `search-index-playground.mongodb.js` (normalmente en la parte inferior izquierda del Explorador).
  ![MongoDB Playground](../../../assets/images/playground.png)

---

### 🖥️ Validación Frontend

**Verifica el Estado del Ejercicio:**  
Ve a la aplicación y comprueba si el indicador del ejercicio muestra verde, lo que indica que tu implementación es correcta.

![search-index](../../../assets/images/search-index.png)

---

### 🚦 Qué Esperar

Una vez que tu índice esté activo, tu plataforma estará lista para búsqueda de texto completo ultrarrápida y filtros dinámicos. El autocompletado, la navegación facetada y los resultados instantáneos estarán a solo una consulta de distancia.

Con este paso, no solo estás configurando campos—estás construyendo la columna vertebral de una experiencia de búsqueda de clase mundial.  
**¿Listo para hacer tus datos descubribles? ¡Comencemos!**

{% include simple_next_nav.html %}

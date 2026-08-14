---
title: "Atlas Vector Search: vectorSearch"
permalink: /es/vector-search/1/
layout: single
classes: wide
lang: es
---

<details>
<summary>📋 Referencia del Lab</summary>
<p><strong>Archivo de Lab Asociado:</strong> <code>vector-search-1.lab.js</code></p>
</details>

## 🚀 Objetivo: Búsqueda Semántica que Impresiona

Tu negocio quiere hacer que buscar la estancia perfecta sea fácil e inteligente. Imagina a un huésped escribiendo una consulta en lenguaje natural e instantáneamente viendo sugerencias inteligentes y conscientes de la intención. Como ingeniero backend, estás a punto de dar vida a esta búsqueda de siguiente nivel con MongoDB Atlas Vector Search.

¡Aprovecha el poder de MongoDB Atlas Vector Search para construir una función de búsqueda semántica que tus usuarios amarán!

---

### 🧩 Ejercicio: Búsqueda Semántica como un Profesional

1. **Abre el Archivo**  
   Ve a `server/src/lab/` y abre `vector-search-1.lab.js`.

2. **Encuentra la Función**  
   Localiza la función `vectorSearch`.

3. **Define el Pipeline**  
   - Agrega una etapa `$vectorSearch` usando tu índice `vector_index`.  
   - Usa el campo `description` como ruta de búsqueda vectorial.  
   - Pasa la cadena de consulta del usuario como `query: { text: query }` (requerido por el índice `autoEmbed`).
   - Agrega un filtro en `property_type` para resultados más relevantes.  
   - Establece `numCandidates` en 100 y `limit` en 10 en la etapa `$vectorSearch`.  

---

### 🚦 Prueba tu API

1. Ve a `server/src/lab/rest-lab`.  
2. Abre `vector-search-1-lab.http`.  
3. Haz clic en **Send Request** para llamar a la API.
4. Confirma que la respuesta contiene los resultados semánticamente relevantes esperados.

---

### 🖥️ Validación Frontend

Escribe una consulta en lenguaje natural (p. ej., `"best view in hawaii"`) en la barra de búsqueda y observa cómo aparecen sugerencias inteligentes y relevantes—¡potenciadas por IA y búsqueda vectorial!

**Verifica el Estado del Ejercicio:**  
Ve a la aplicación y comprueba si el indicador del ejercicio muestra verde, lo que indica que tu implementación es correcta.

Con este paso, no solo estás construyendo una función—estás habilitando una nueva era de descubrimiento y deleite para tus usuarios.  
**¿Listo para sorprender a tus huéspedes con búsqueda semántica? ¡Comencemos!**

![vector-search-1-lab](../../../assets/images/vector-search-1-lab.png)

{% include simple_next_nav.html %}

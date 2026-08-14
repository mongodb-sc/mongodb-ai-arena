---
title: "Atlas Vector Search: Creación de Índice"
permalink: /es/vector-search/index/
layout: single
classes: wide
categories: [vector-search]
lang: es
---

## 🚀 Objetivo: Habilita la Búsqueda Semántica con Índices de Atlas Vector Search

Tus usuarios quieren búsqueda más inteligente potenciada por IA—encontrando la estancia perfecta incluso con consultas en lenguaje natural. Para lograrlo, crearás un **índice de Vector Search** en MongoDB Atlas. Como ingeniero backend, estás construyendo la base para búsqueda semántica, IA conversacional y descubrimiento de siguiente nivel.

En este ejercicio, configurarás un índice vectorial que habilita la búsqueda semántica en las descripciones de tus listados, usando el modelo de embedding integrado de MongoDB.

---

### 🧩 Ejercicio: Construye tu Índice de Vector Search

Configura tu índice con estas especificaciones:

- **Nombre del Índice:** `vector_index`
- **Ruta del Campo de Texto:** `description`
- **Modelo de Embedding:** `voyage-3-large`
- **Ruta del Campo de Filtro:** `property_type`

---

### 🛠️ Cómo Completar este Ejercicio

Elige tu herramienta favorita e indexa:
- Interfaz web de **MongoDB Atlas**
- **MongoDB Compass**
- **Extensión de MongoDB** con el MongoDB Playground proporcionado

#### 💻 **¿Usas VS Code?**
- Sugerimos usar la función Playground para una experiencia rápida e interactiva.
- En VSCode Online, localiza y abre el archivo `vector-search-index-playground.mongodb.js`.
  ![MongoDB Playground](../../../assets/images/playground.png)

---

### 🖥️ Validación Frontend

**Verifica el Estado del Ejercicio:**  
Ve a la aplicación y comprueba si el indicador del ejercicio muestra verde, lo que indica que tu implementación es correcta.

![vector-search-index](../../../assets/images/vector-search-index.png)

---

### 🚦 Qué Esperar

Con tu índice vectorial activo, tu plataforma estará lista para:
- **Búsqueda semántica** que entiende la intención del usuario, no solo las palabras clave
- **Chatbots potenciados por IA** que relacionan consultas de huéspedes con los mejores listados
- **Resultados más rápidos y relevantes** con filtrado por tipo de propiedad
- La base para experiencias de descubrimiento conversacional avanzadas

No solo estás indexando datos—estás habilitando la próxima generación de búsqueda e IA para tu plataforma.  
**¿Listo para desbloquear la búsqueda semántica? ¡Comencemos!**

{% include simple_next_nav.html %}

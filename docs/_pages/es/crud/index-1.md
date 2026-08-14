---
title: "Índice 1"
permalink: /es/crud/index/
layout: single
classes: wide
lang: es
---

## 🚀 Objetivo: Turboalimenta tus Consultas con Índices

Tu plataforma está creciendo, y tus usuarios esperan resultados instantáneos—ya sea que busquen el precio perfecto o el número correcto de camas. Como ingeniero backend, tienes el poder de hacer cada búsqueda ultrarrápida y cada filtro súper eficiente. ¡Los índices son tu arma secreta!

En este ejercicio, crearás un índice compuesto para potenciar tus consultas, asegurando que tu plataforma se mantenga ágil a medida que crecen tus datos.

---

### 💡 Ejercicio: Construye un Índice Compuesto

Crea un índice compuesto con estas especificaciones:

1. **Campos a Incluir**
   - `beds` (ascendente)
   - `price` (ascendente)

2. **Nombre del Índice**
   - Nómbralo: `beds_1_price_1`

---

### 🛠️ Cómo Crear tu Índice

Elige tu herramienta favorita e indexa:

#### 🎯 **Métodos Tradicionales**
- Interfaz web de **MongoDB Atlas**
- **MongoDB Compass**
- **Extensión de MongoDB** con el MongoDB Playground proporcionado

#### 💻 **¿Usas VS Code?**
- Sugerimos usar la función Playground para una experiencia rápida e interactiva.
- En VSCode Online, localiza y abre el archivo `index-playground.mongodb.js` (normalmente en la parte inferior izquierda del Explorador).
  ![MongoDB Playground](../../../assets/images/playground.png)

#### 🤖 **Método con IA (Si Está Disponible)**
- **MongoDB MCP (Model Context Protocol)** - Si tienes MCP disponible, simplemente pídele a tu asistente de IA:
  
  *"Crea un índice compuesto en la colección listingsAndReviews con beds (ascendente) y price (ascendente), llamado 'beds_1_price_1'"*
  
  ¡Tu IA con MCP habilitado puede ejecutar la creación del índice directamente para ti! 🚀

💡 Consejo profesional: ¡Los índices compuestos son tu arma secreta para consultas de múltiples campos!

---

### 🖥️ Validación Frontend

**Verifica el Estado del Ejercicio:**  
Ve a la aplicación y comprueba si el indicador del ejercicio muestra verde, lo que indica que tu implementación es correcta.

![crud-index](../../../assets/images/crud-index.png)

{% include simple_next_nav.html %}

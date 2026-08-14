---
title: "Análisis de Rendimiento de Anfitriones"
permalink: /es/pipeline/2/
layout: single
classes: wide
lang: es
---

<details>
<summary>📋 Referencia del Lab</summary>
<p><strong>Archivo de Lab Asociado:</strong> <code>pipeline-2.lab.js</code></p>
</details>

## 🚀 Objetivo: Análisis de Rendimiento Superanfitrión vs Anfitrión Regular

El éxito de tu plataforma depende de entender qué hace excepcionales a los anfitriones. El equipo de marketing quiere mostrar la "ventaja Superanfitrión" para atraer anfitriones de calidad, mientras que el equipo de producto necesita perspectivas para mejorar la incorporación de anfitriones. Como ingeniero backend, eres el detective de datos que puede desbloquear los secretos ocultos en documentos de anfitriones anidados.

En este ejercicio, aprovecharás el poder de MongoDB para trabajar con documentos anidados.

---

### 🎯 Desiderata del Ejercicio: Qué Necesitas Construir

Tu misión es crear un pipeline de agregación que muestre análisis de datos avanzados:

**🔍 Control de Calidad de Datos:**
- Filtra listados legítimos: `price > 0` y `number_of_reviews > 0`
- Enfócate en propiedades con actividad de mercado real y comentarios de huéspedes

**🏗️ Transformación Inteligente de Datos:**
- Maneja datos faltantes de `host.host_is_superhost` con gracia (trata los faltantes como "no superanfitrión")
- Crea campos calculados dinámicamente dentro del pipeline

**📊 Inteligencia Empresarial:**
- Compara Superanfitriones vs Anfitriones Regulares en múltiples dimensiones:
  - Calificaciones promedio, conteos de reseñas y estrategias de precios
  - Tamaños de portafolio de anfitriones y tasas de respuesta

**🎨 Formato de Salida Limpio:**
- Transforma nombres de campos técnicos en etiquetas amigables para el negocio
- Redondea valores numéricos apropiadamente para la presentación

### 🧩 Ejercicio: Implementación Paso a Paso

1. **Abre el Archivo**  
   Navega a `server/src/lab/` y abre `pipeline-2.lab.js`.

2. **Encuentra la Función**  
   Localiza la función `hostPerformanceAnalytics` con instrucciones detalladas.

3. **Construye el Pipeline de 5 Etapas**  
   - **Etapa 1 - $match**: Filtra datos de calidad (`price > 0`, `number_of_reviews > 0`)
   - **Etapa 2 - $addFields**: Crea campo `isSuperhost` usando `$ifNull` para manejar datos faltantes
   - **Etapa 3 - $group**: Agrupa por estado de superanfitrión y calcula 6 métricas clave
   - **Etapa 4 - $project**: Transforma la salida con etiquetas legibles y redondeo apropiado
   - **Etapa 5 - $sort**: Ordena por calificación promedio (descendente) para perspectivas empresariales

---

### 🚦 Prueba tu API

1. Ve a `server/src/lab/rest-lab`.
2. Abre `pipeline-2-host-analytics-lab.http`.
3. Haz clic en **Send Request** para llamar a la API.
4. ¡Admira las perspectivas comparando Superanfitriones vs anfitriones regulares!

---

### 🖥️ Validación Frontend

- Verifica la sección "Host Analytics" para ver tu análisis de documentos anidados en acción.

**Verifica el Estado del Ejercicio:**  
Ve a la aplicación y verifica que el indicador del ejercicio muestra verde, confirmando tu dominio de las agregaciones de documentos anidados.

¡Este ejercicio muestra la capacidad natural de MongoDB para trabajar con estructuras de datos complejas y anidadas!  
**¿Listo para desbloquear el poder de los documentos anidados? ¡Comencemos!**

![pipeline-2-lab](../../../assets/images/pipeline-2-lab.png)

{% include simple_next_nav.html %}

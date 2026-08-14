---
title: "Atlas Search: Facet"
permalink: /es/search/2/
layout: single
classes: wide
lang: es
---

<details>
<summary>📋 Referencia del Lab</summary>
<p><strong>Archivo de Lab Asociado:</strong> <code>search-2.lab.js</code></p>
</details>

## 🚀 Objetivo: Búsqueda Facetada que Brilla

La búsqueda de tu plataforma ya es rápida e inteligente, pero ahora tu negocio quiere empoderar a los usuarios para explorar y filtrar resultados con facilidad. Imagina a un huésped buscando "hawaii" e instantáneamente reduciendo los resultados por comodidades, tipo de propiedad o número de camas—todo con un solo clic. Como ingeniero backend, estás a punto de hacer realidad esta experiencia de descubrimiento de siguiente nivel con las facetas de MongoDB Atlas Search.

La búsqueda facetada permite a tus usuarios dividir y analizar los resultados, haciendo que sea fácil encontrar exactamente lo que quieren.

---

### 🧩 Ejercicio: Facetas en Acción

1. **Abre el Archivo**  
   Navega a `server/src/lab/` y abre `search-2.lab.js`.

2. **Localiza la Función**  
   Encuentra la función `facetSearch` en el archivo.

3. **Define el Pipeline**  
   - Usa `$searchMeta` en el índice `search_index`.  
   - Aplica `facet` en tu pipeline.  
   - Para el `operator`, reutiliza la búsqueda `autocomplete` del ejercicio anterior.  
   - Crea estas facetas:  
     - `amenities`: una faceta de cadena  
     - `property_type`: una faceta de cadena  
     - `beds`: una faceta numérica con límites de 0 a 9, y "Other" para valores adicionales  

---

### 🚦 Prueba tu API

1. Ve a `server/src/lab/rest-lab`.  
2. Abre `search-2-facet-lab.http`.  
3. Haz clic en **Send Request** para llamar a la API.  
4. Asegúrate de ver resultados válidos en la respuesta.

---

### 🖥️ Validación Frontend

Escribe `"hawaii"` en la barra de búsqueda y observa cómo aparecen las nuevas facetas—¡filtra y explora tus resultados al instante!

**Verifica el Estado del Ejercicio:**  
Ve a la aplicación y comprueba si el indicador del ejercicio muestra verde, lo que indica que tu implementación es correcta.

Con este paso, no solo estás agregando filtros—estás dando a tus usuarios el poder de descubrir su estancia perfecta, a su manera.  
**¿Listo para hacer la búsqueda verdaderamente interactiva? ¡Comencemos!**

![search-2-lab](../../../assets/images/search-2-lab.png)

{% include simple_next_nav.html %}

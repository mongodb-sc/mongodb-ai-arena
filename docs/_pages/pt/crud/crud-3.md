---
title: "Operações CRUD: Distinct"
permalink: /pt/crud/3/
layout: single
classes: wide
lang: pt
---

<details>
<summary>📋 Referência do Lab</summary>
<p><strong>Arquivo de Lab Associado:</strong> <code>crud-3.lab.js</code></p>
</details>

## 🚀 Objetivo: Descobrir Valores Únicos como um Profissional

Sua plataforma está evoluindo, e agora é hora de dar a seus usuários o poder de filtrar e explorar anúncios de novas maneiras. Imagine um hóspede buscando propriedades por bairro, comodidades ou tipo de propriedade—filtros dinâmicos tornam tudo isso possível. Como engenheiro backend, você usará o `distinct` do MongoDB para desbloquear essas funcionalidades.

Neste exercício, você revelará todos os valores únicos em qualquer campo, potencializando os filtros que ajudam os hóspedes a encontrar exatamente o que procuram.

---

### 🧩 Exercício: Encontrar Valores Únicos

1. **Abra o Arquivo**  
   Navegue para `server/src/lab/` e abra `crud-3.lab.js`.

2. **Localize a Função**  
   Encontre a função `crudDistinct` no arquivo.

3. **Defina a Consulta**  
   - Use o método `distinct` para recuperar todos os valores únicos do campo especificado pelo parâmetro `field_name`.
   - Retorne um array de todos os valores distintos encontrados naquele campo em toda a coleção.

---

### 🚦 Teste sua API

1. Vá para `server/src/lab/rest-lab`.
2. Abra `crud-3-distinct-lab.http`.
3. Clique em **Send Request** para executar a chamada da API.
4. Verifique se a resposta retorna uma lista de valores únicos para o campo solicitado.

---

### 🖥️ Validação Frontend

Abra o painel de "Filtros" no aplicativo e veja como todos os valores distintos para o campo escolhido aparecem—habilitando filtros dinâmicos e amigáveis para seus hóspedes.

**Verifique o Status do Exercício:**  
Vá para o aplicativo e veja se o indicador do exercício mostra verde, indicando que sua implementação está correta.

Com este passo, você não está apenas buscando dados—está capacitando seus usuários a descobrir a estadia perfeita, do jeito deles.  
**Pronto para tornar sua plataforma mais inteligente e interativa? Vamos começar!**

![crud-3-lab](../../../assets/images/crud-3-lab.png)

{% include simple_next_nav.html %}

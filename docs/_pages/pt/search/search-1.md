---
title: "Atlas Search: Autocomplete"
permalink: /pt/search/1/
layout: single
classes: wide
lang: pt
---

<details>
<summary>📋 Referência do Lab</summary>
<p><strong>Arquivo de Lab Associado:</strong> <code>search-1.lab.js</code></p>
</details>

## 🚀 Objetivo: Autocomplete que Impressiona

Seu negócio quer tornar a busca pela estadia perfeita fácil e deliciosa. Imagine um hóspede digitando apenas algumas letras e instantaneamente vendo sugestões inteligentes e tolerantes a erros de digitação. Como engenheiro backend, você está prestes a dar vida a essa mágica com o MongoDB Atlas Search.

Aproveite a magia do MongoDB Atlas Search para construir um recurso de autocomplete rápido e elegante que seus usuários vão adorar!

---

### 🧩 Exercício: Autocomplete como um Profissional

1. **Abra o Arquivo**  
   Vá para `server/src/lab/` e abra `search-1.lab.js`.

2. **Encontre a Função**  
   Localize a função `autocompleteSearch`.

3. **Defina o Pipeline**  
   - Adicione um estágio `$search` no índice `search_index`.  
   - Use `autocomplete` no campo `name`.  
   - Habilite a pesquisa `fuzzy` para resultados tolerantes a erros de digitação.  
   - Limite os resultados a 10 documentos.  
   - Use `$project` para retornar apenas o campo `name`.

---

### 🚦 Teste sua API

1. Vá para `server/src/lab/rest-lab`.  
2. Abra `search-1-autocomplete-lab.http`.  
3. Clique em **Send Request** para chamar a API.  
4. Confirme que a resposta contém os resultados esperados.

---

### 🖥️ Validação Frontend

Digite `"hawaii"` na barra de pesquisa e veja as sugestões de autocomplete aparecerem como mágica—rápidas, relevantes e fáceis de usar!

**Verifique o Status do Exercício:**  
Vá para o aplicativo e veja se o indicador do exercício mostra verde, indicando que sua implementação está correta.

Com este passo, você não está apenas construindo um recurso—está tornando seus usuários felizes e sua plataforma inesquecível.  
**Pronto para impressionar seus hóspedes com pesquisa instantânea? Vamos começar!**

![search-1-lab](../../../assets/images/search-1-lab.png)

{% include simple_next_nav.html %}

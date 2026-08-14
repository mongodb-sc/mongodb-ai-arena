---
title: "Operações CRUD: Set"
permalink: /pt/crud/6/
layout: single
classes: wide
lang: pt
---

<details>
<summary>📋 Referência do Lab</summary>
<p><strong>Arquivo de Lab Associado:</strong> <code>crud-6.lab.js</code></p>
</details>

## 🚀 Objetivo: Atualizar Qualquer Campo com $set—como um Profissional

Sua plataforma está prosperando, e seus usuários esperam flexibilidade—seja atualizando o título de uma propriedade, adicionando uma nova comodidade ou corrigindo um erro de digitação. Como engenheiro backend, você é quem torna essas atualizações em tempo real possíveis, mantendo seus dados frescos e seus usuários felizes.

Neste exercício, você aproveitará o poder do operador `$set` do MongoDB para atualizar qualquer campo em seus documentos.

---

### 🧩 Exercício: Atualizar um Documento

1. **Abra o Arquivo**  
   Navegue para `server/src/lab/` e abra `crud-6.lab.js`.

2. **Localize a Função**  
   Encontre a função `crudUpdateElement` no arquivo.

3. **Defina a Atualização**  
   - A função recebe três parâmetros:
     - `id`: O `_id` do documento
     - `key`: O nome do campo a ser atualizado
     - `value`: O novo valor a ser definido
   - Use `$set` para atualizar o campo especificado com o novo valor—dinâmico, flexível e poderoso!

---

### 🚦 Teste sua API

1. Vá para o diretório `server/src/lab/rest-lab`.
2. Abra `crud-6-update-lab.http`.
3. Clique em **Send Request** para executar a chamada da API.
4. Verifique se a resposta mostra o documento com o campo atualizado.

---

### 🖥️ Validação Frontend

Edite um campo (como o Título) de um anúncio no aplicativo e veja suas alterações persistirem—mesmo após uma atualização.

**Verifique o Status do Exercício:**  
Vá para o aplicativo e veja se o indicador do exercício mostra verde, indicando que sua implementação está correta.

Com este passo, você não está apenas atualizando dados—está mantendo sua plataforma fresca, relevante e responsiva às necessidades de cada usuário.  
**Pronto para dar um novo visual aos seus dados? Vamos começar!**

![crud-6-lab](../../../assets/images/crud-6-lab.png)

{% include simple_next_nav.html %}

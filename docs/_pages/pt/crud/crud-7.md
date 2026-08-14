---
title: "Operações CRUD: Push"
permalink: /pt/crud/7/
layout: single
classes: wide
lang: pt
---

<details>
<summary>📋 Referência do Lab</summary>
<p><strong>Arquivo de Lab Associado:</strong> <code>crud-7.lab.js</code></p>
</details>

## 🚀 Objetivo: Adicionar a Arrays sem Esforço com $push

Sua plataforma está prosperando, e os hóspedes estão ansiosos para compartilhar suas experiências. Imagine um viajante deixando uma avaliação brilhante após uma estadia perfeita, ou um anfitrião recebendo feedback valioso. Como engenheiro backend, você torna esses momentos possíveis—atualizando instantaneamente os anúncios com novas avaliações.

Neste exercício, você usará o operador `$push` do MongoDB para adicionar avaliações (ou qualquer item de array) aos seus documentos.

---

### 🧩 Exercício: Adicionar uma Avaliação a um Array

1. **Abra o Arquivo**  
   Navegue para `server/src/lab/` e abra `crud-7.lab.js`.

2. **Localize a Função**  
   Encontre a função `crudAddToArray` no arquivo.

3. **Atualize o Código**  
   - Use `$push` para adicionar a nova avaliação ao array `reviews`.
   - A função recebe dois parâmetros:
     - `id`: O `_id` do documento
     - `review`: O objeto de avaliação a adicionar
   - Use `$inc` para incrementar o campo `number_of_reviews` em 1.

---

### 🚦 Teste sua API

1. Vá para o diretório `server/src/lab/rest-lab`.
2. Abra `crud-7-reviews-lab.http`.
3. Clique em **Send Request** para executar a chamada da API.
4. Verifique se a resposta mostra o documento atualizado com a nova avaliação.

---

### 🖥️ Validação Frontend

Adicione uma nova avaliação no aplicativo e veja ela aparecer instantaneamente para o anúncio selecionado—suave, dinâmica e satisfatória!

**Verifique o Status do Exercício:**  
Vá para o aplicativo e veja se o indicador do exercício mostra verde, indicando que sua implementação está correta.

Com este passo, você não está apenas atualizando arrays—está capturando as histórias e feedbacks que dão vida à sua plataforma.  
**Pronto para dar voz aos seus usuários? Vamos começar!**

![crud-7-lab](../../../assets/images/crud-7-lab.png)

{% include simple_next_nav.html %}

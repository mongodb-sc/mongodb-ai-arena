---
title: "Operações CRUD: Find One"
permalink: /pt/crud/2/
layout: single
classes: wide
lang: pt
---

<details>
<summary>📋 Referência do Lab</summary>
<p><strong>Arquivo de Lab Associado:</strong> <code>crud-2.lab.js</code></p>
</details>

## 🚀 Objetivo: Recuperar um Único Documento Instantaneamente

Sua plataforma está crescendo, e agora seus usuários querem mais do que apenas uma lista—eles querem detalhes! Imagine um hóspede clicando em uma propriedade para ver cada foto, comodidade e avaliação. Como engenheiro backend, é seu trabalho entregar essas informações instantânea e precisamente.

Neste exercício, você desbloqueará o poder do `findOne` do MongoDB para buscar exatamente o que seus usuários precisam.

---

### 🧩 Exercício: Buscar Um Documento

1. **Abra o Arquivo**  
   Navegue para `server/src/lab/` e abra `crud-2.lab.js`.

2. **Localize a Função**  
   Encontre a função `crudOneDocument` no arquivo.

3. **Defina a Consulta**  
   - Implemente a função para encontrar um documento onde `_id` seja igual ao parâmetro `id` fornecido.
   - Retorne o documento completo que corresponda a este critério.

---

### 🚦 Teste sua API

1. Vá para `server/src/lab/rest-lab`.
2. Abra `crud-2-one-lab.http`.
3. Clique em **Send Request** para executar a chamada da API.
![test-rest-lab](../../../assets/images/test-rest-lab.png)
4. Verifique se a resposta retorna o único documento solicitado.

---

### 🖥️ Validação Frontend

> **Importante:**  
> Para verificar se sua implementação funciona, **vá à página inicial do aplicativo e selecione um anúncio**.  
> Isso abrirá a página de detalhes daquela propriedade e acionará seu novo código de API.

- Quando você selecionar um anúncio, todos os detalhes daquela propriedade devem aparecer—rápidos, focados e impecáveis.
- **Verifique o Status do Exercício:**  
  Procure o indicador do exercício na página de detalhes. Se mostrar verde, sua implementação está correta!

Com este passo, você não está apenas recuperando dados—está dando vida a cada anúncio para seus usuários.  
**Pronto para entregar os detalhes que fazem sua plataforma brilhar? Vamos começar!**

![crud-2-lab](../../../assets/images/crud-2-lab.png)

{% include simple_next_nav.html %}

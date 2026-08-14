---
title: "Operações CRUD: Find/Query"
permalink: /pt/crud/4/
layout: single
classes: wide
lang: pt
---

<details>
<summary>📋 Referência do Lab</summary>
<p><strong>Arquivo de Lab Associado:</strong> <code>crud-4.lab.js</code></p>
</details>

## 🚀 Objetivo: Filtragem Avançada e Paginação como um Profissional

Sua plataforma agora está repleta de anúncios, e seus usuários querem encontrar sua estadia perfeita—rápido. Imagine um hóspede procurando um apartamento aconchegante com banheira de hidromassagem, ou uma família procurando uma casa com o número certo de camas. Como engenheiro backend, é seu trabalho tornar essas buscas fluidas e poderosas.

Neste exercício, você combinará múltiplos filtros e paginação para criar uma experiência de busca dinâmica e amigável.

---

### 🧩 Exercício: Buscar Documentos com Filtros

1. **Abra o Arquivo**  
   Navegue para `server/src/lab/` e abra `crud-4.lab.js`.

2. **Localize a Função**  
   Encontre a função `crudFilter` no arquivo.

3. **Defina a Consulta**  
   - Filtre por:
     - `amenities`: array de comodidades selecionadas
     - `propertyType`: tipo específico de propriedade
     - `beds`: faixa de camas (formato: "2-3", "4-7")
   - Adicione paginação com:
     - `skip`: número de documentos a pular
     - `limit`: máximo de documentos a retornar
   - Sem filtros? Retorne todos os documentos (com paginação).

---

### 🚦 Teste sua API

1. Vá para `server/src/lab/rest-lab`.
2. Abra `crud-4-filter-lab.http`.
3. Clique em **Send Request** para executar a chamada da API.
4. Confirme que a resposta retorna documentos que correspondem aos seus filtros.

---

### 🖥️ Validação Frontend

Defina diferentes filtros no painel de "Filtros" do aplicativo e veja seus anúncios atualizarem em tempo real—rápido, flexível e fácil de usar!

**Verifique o Status do Exercício:**  
Vá para o aplicativo e veja se o indicador do exercício mostra verde, indicando que sua implementação está correta.

Com este passo, você não está apenas filtrando dados—está ajudando cada hóspede a encontrar sua estadia perfeita.  
**Pronto para tornar sua plataforma verdadeiramente dinâmica? Vamos começar!**

![crud-4-lab](../../../assets/images/crud-4-lab.png)

{% include simple_next_nav.html %}

---
title: "Operações CRUD: Find"
permalink: /pt/crud/1/
layout: single
classes: wide
lang: pt
---

<details>
<summary>📋 Referência do Lab</summary>
<p><strong>Arquivo de Lab Associado:</strong> <code>crud-1.lab.js</code></p>
</details>

## 🚀 Objetivo: Buscar, Ordenar e Paginar como um Profissional

A jornada de sua empresa no mercado de aluguel de curto prazo acabou de começar, e o primeiro desafio é claro: você precisa ajudar seus usuários a descobrir o lugar perfeito para ficar. Como engenheiro backend, é seu trabalho tornar a busca de anúncios rápida, precisa e deliciosa.

Neste exercício, você dominará os conceitos básicos do MongoDB buscando documentos, ordenando resultados e adicionando paginação fluida às suas consultas.

---

### 🧩 Exercício: Buscar Documentos

1. **Abra o Arquivo**  
   Vá para `server/src/lab/` e abra `crud-1.lab.js`.

2. **Localize a Função**  
   Encontre a função `crudFind` no arquivo.

3. **Defina a Consulta**  
   - Encontre todos os documentos que correspondam ao parâmetro `query` fornecido.
   - Ordene os resultados por `_id` em ordem ascendente.
   - Adicione paginação com:
     - `skip`: número de documentos a pular
     - `limit`: máximo de documentos a retornar

---

### 🚦 Teste sua API

1. Vá para `server/src/lab/rest-lab`.
2. Abra `crud-1-query-lab.http`.
3. Clique em **Send Request** para executar a chamada da API.
![test-rest-lab](../../../assets/images/test-rest-lab.png)
4. Verifique se a resposta retorna os resultados paginados.

---

### 🖥️ Validação Frontend

Depois que sua lógica backend estiver implementada, atualize a página inicial e veja seus anúncios aparecerem—prontos para seus futuros hóspedes explorarem.

**Verifique o Status do Exercício:**  
Vá para o aplicativo e veja se o indicador do exercício mostra verde, indicando que sua implementação está correta.

Com este primeiro passo, você não está apenas escrevendo código—está construindo a experiência de busca que ajudará sua empresa a se destacar no mercado de aluguéis.  
**Pronto para ajudar seus usuários a encontrar sua próxima estadia? Vamos começar!**

![crud-1-lab](../../../assets/images/crud-1-lab.png)

{% include simple_next_nav.html %}

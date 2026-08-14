---
title: "Índice 1"
permalink: /pt/crud/index/
layout: single
classes: wide
lang: pt
---

## 🚀 Objetivo: Turboalimenta suas Consultas com Índices

Sua plataforma está crescendo, e seus usuários esperam resultados instantâneos—seja procurando o preço perfeito ou o número certo de camas. Como engenheiro backend, você tem o poder de tornar cada busca ultrarrápida e cada filtro super eficiente. Os índices são sua arma secreta!

Neste exercício, você criará um índice composto para potencializar suas consultas, garantindo que sua plataforma permaneça ágil à medida que seus dados crescem.

---

### 💡 Exercício: Construa um Índice Composto

Crie um índice composto com estas especificações:

1. **Campos a Incluir**
   - `beds` (ascendente)
   - `price` (ascendente)

2. **Nome do Índice**
   - Nomeie: `beds_1_price_1`

---

### 🛠️ Como Criar seu Índice

Escolha sua ferramenta favorita e indexe:

#### 🎯 **Métodos Tradicionais**
- Interface web do **MongoDB Atlas**
- **MongoDB Compass**
- **Extensão do MongoDB** com o MongoDB Playground fornecido

#### 💻 **Usando VS Code?**
- Sugerimos usar o recurso Playground para uma experiência rápida e interativa.
- No VSCode Online, localize e abra o arquivo `index-playground.mongodb.js` (geralmente encontrado no canto inferior esquerdo do Explorer).
  ![MongoDB Playground](../../../assets/images/playground.png)

#### 🤖 **Método com IA (Se Disponível)**
- **MongoDB MCP (Model Context Protocol)** - Se você tiver MCP disponível, simplesmente peça ao seu assistente de IA:
  
  *"Crie um índice composto na coleção listingsAndReviews com beds (ascendente) e price (ascendente), chamado 'beds_1_price_1'"*
  
  Seu IA habilitado para MCP pode executar a criação do índice diretamente para você! 🚀

💡 Dica profissional: Índices compostos são sua arma secreta para consultas de múltiplos campos!

---

### 🖥️ Validação Frontend

**Verifique o Status do Exercício:**  
Vá para o aplicativo e veja se o indicador do exercício mostra verde, indicando que sua implementação está correta.

![crud-index](../../../assets/images/crud-index.png)

{% include simple_next_nav.html %}

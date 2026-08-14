---
title: "Análise do Mercado de Investimento Imobiliário"
permalink: /pt/pipeline/1/
layout: single
classes: wide
lang: pt
---

<details>
<summary>📋 Referência do Lab</summary>
<p><strong>Arquivo de Lab Associado:</strong> <code>pipeline-1.lab.js</code></p>
</details>

## 🚀 Objetivo: Análise Inteligente de Investimento Imobiliário

Sua plataforma chamou a atenção de investidores imobiliários que precisam de insights baseados em dados para tomar decisões de investimento informadas. Eles querem entender segmentos de mercado, padrões de preços e desempenho de propriedades por número de camas. Como engenheiro backend, sua tarefa é criar uma análise de mercado que revele oportunidades de investimento.

Neste exercício fundamental de agregação, você aprenderá conceitos essenciais do pipeline do MongoDB analisando segmentos do mercado imobiliário.

---

### 🎯 Desiderata do Exercício: O Que Você Precisa Construir

Sua missão é criar um pipeline de agregação que forneça uma análise limpa do mercado de investimento:

**🔍 Controle de Qualidade de Dados:**
- Filtre propriedades de investimento legítimas: `price > 0` e `number_of_reviews > 0`
- Foque em propriedades residenciais com `beds` entre 0-10 e `accommodates > 0`
- Exclua dados de teste e valores extremos que distorceriam a análise

**📊 Segmentação de Mercado:**
- Agrupe propriedades por número de camas para criar segmentos de mercado significativos
- Calcule métricas-chave de investimento: preço médio, tamanho do mercado e atividade de hóspedes
- Gere insights para cada segmento desde estúdios (0 camas) até casas grandes (10 camas)

**🎨 Saída Pronta para o Negócio:**
- Transforme dados técnicos em formato amigável para investidores
- Arredonde valores numéricos adequadamente para apresentação financeira
- Remova campos técnicos do MongoDB para relatórios de negócios limpos

### 🧩 Exercício: Implementação Passo a Passo

1. **Abra o Arquivo**  
   Navegue para `server/src/lab/` e abra `pipeline-1.lab.js`.

2. **Encontre a Função**  
   Localize a função `aggregationPipeline` com instruções detalhadas.

3. **Construa o Pipeline de 4 Estágios**  
   - **Estágio 1 - $match**: Filtre propriedades de investimento de qualidade
   - **Estágio 2 - $group**: Agrupe por campo `beds` e calcule métricas
   - **Estágio 3 - $project**: Transforme a saída com arredondamento adequado
   - **Estágio 4 - $sort**: Ordene por campo `beds` ascendente

---

### 🚦 Teste sua API

1. Vá para `server/src/lab/rest-lab`.
2. Abra `pipeline-1-statistics-lab.http`.
3. Clique em **Send Request** para chamar a API.
4. Verifique se você obtém segmentos de mercado com preços e contagens de propriedades!

---

### 🖥️ Validação Frontend

- Verifique a seção "Show Statistics" para ver sua análise de mercado em ação.

**Verifique o Status do Exercício:**  
Vá para o aplicativo e verifique que o indicador do exercício mostra verde.

**Pronto para desbloquear insights de mercado através da agregação de dados? Vamos começar!**

![pipeline-1-lab](../../../assets/images/pipeline-1-lab.png)

{% include simple_next_nav.html %}

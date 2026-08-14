---
title: "Ambiente: VSCode"
permalink: /pt/guided/vscode/
layout: single
classes: wide
lang: pt
---

## 🌐💡 VSCode Online: Seu Playground na Nuvem

Bem-vindo ao seu playground de desenvolvimento na nuvem!  
Vamos conectar você, programar e explorar o MongoDB em grande estilo.

**Estamos aqui para _vibe code_ essa experiência juntos—vamos torná-la inesquecível! 🚀🎶**

---

## 🚀 Passo 1: Configuração do Backend

1. **Acesse o VSCode Online:**
   - Navegue até o Portal da Arena e verifique se seu nome aparece na lista de participantes. Se não estiver lá, preencha o formulário "Novo na Arena?".
   - Abra o `Workspace`
     ![Folder View](../../../assets/images/environment-homepage.png)  
2. **Confie no Workspace:**
   - Quando solicitado:
     - Clique em **Yes, I trust the author**
     - Clique em **Mark Done**
   ![Trust Prompt](../../../assets/images/environment-folder-trust.png)

3. **Inicie o Servidor:**
   - Abra um novo terminal:
     ```
     ☰ > Terminal > New Terminal
     ```
     ![MongoDB Playground](../../../assets/images/environment-terminal.png)
   - Inicie o backend:
     ```bash
     npm start
     ```
   - ✅ **Verificação:** Se você ver uma mensagem de conexão MongoDB nos logs, está tudo pronto!

---

## 🎨 Passo 2: Configuração do Frontend

1. **Inicie o Aplicativo:**
   - Navegue até o Portal da Arena e abra o `App`

2. **Valide o Frontend:**    
   - Vê seu nome na página inicial? ✅ Você está dentro!
   ![Frontend Name Display](../../../assets/images/environment-working.png)

   - Se você ver a mensagem de erro em vez do seu nome, verifique se o servidor backend está em execução.
   ![Frontend Name Display](../../../assets/images/environment-notworking.png)
   - Ainda não funciona? Chame seu SA para ajuda!

---

## 🔗 Passo 3: Conectar a Extensão MongoDB

1. **Primeiro, Verifique se a Conexão já Existe:**
   - Clique na **extensão MongoDB** na barra lateral.
   - Se você já vê uma conexão chamada **MongoDB Arena - seu-usuário** em **CONNECTIONS**, ela já foi configurada para você. Basta clicar para conectar e pular para a Verificação de Sucesso.
   - Nenhuma conexão listada? Siga os passos abaixo para adicioná-la você mesmo.

2. **Obtenha sua String de Conexão:**  
   - Após iniciar seu servidor backend (`npm start`), você verá a string de conexão exibida na saída do terminal.
   - **Copie** a string de conexão completa do terminal.
     ```markdown
     =============================
      🍃 MongoDB Connection String: `mongodb+srv://credentials@cluster.mongodb.net/`
     =============================
     ```
   ![Connection String](../../../assets/images/environment-conn-string.png)

3. **Conecte no VSCode:**
   - Clique na **extensão MongoDB** na barra lateral.
   - Em **CONNECTIONS**, clique em **+** e escolha **Connect with Connection String**.
   - **Cole** seu URI copiado e conecte!

4. **Verificação de Sucesso:**
   - Se você ver seus bancos de dados, está pronto para começar!

## 🔗 Passo 4: Usar o MongoDB Playground

1. **Abra o MongoDB Playground:**  
   - No VSCode Online, localize e abra o arquivo `find-playground.mongodb.js` (geralmente encontrado no canto inferior esquerdo do Explorer).
   ![MongoDB Playground](../../../assets/images/playground.png)

2. **Execute sua Primeira Consulta:**  
   - Clique no botão **Play** ▶️ no canto superior direito do editor para executar o script do playground.

3. **Verifique os Resultados:**  
   - Se sua consulta executar com sucesso e retornar dados do seu banco, você está pronto!
   - Se ver erros, verifique o nome do banco de dados e a conexão.

## 🤖 Passo 5: Potencialize o VSCode com Cline

1. **Inicie o Cline:**  
   - Clique no ícone **Cline** na barra de ferramentas do VSCode para abrir a extensão.
   - Escolha **Use your own API key** quando solicitado.
   ![cline-home](../../../assets/images/cline-home.png)
2. **Configure a API:**
   - Defina **API Provider** como **LiteLLM**.
   - Insira as seguintes configurações do LiteLLM:
     - **Base URL:** `http://litellm-service:4000`
     - **API Key:** `noop`
     - **Model:** `gpt-5-mini`
   - Clique em **Let's go!**  
     ![cline-welcome](../../../assets/images/cline-welcome.png)

3. **Teste o Cline:**
   - Teste sua configuração inserindo um prompt no Cline (por exemplo, peça para ele contar uma piada).
     ![cline-working](../../../assets/images/cline-working.png)

**Dica:**  
Se não receber uma resposta, verifique suas configurações de API ou peça ajuda ao seu SA!

{% include simple_next_nav.html %}

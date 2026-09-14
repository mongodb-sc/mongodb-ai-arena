---
title: "Ambiente: VSCode"
permalink: /pt/guided/vscode-nop/
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

## 🤖 Passo 4: Potencialize o VSCode com Cline

1. **Inicie o Cline:**  
   - Clique no ícone **Cline** na barra de ferramentas do VSCode para abrir a extensão.
   - Escolha **Use your own API key** quando solicitado.
   ![cline-home](../../../assets/images/cline-home.png)
2. **Configure a API:**
   - Defina **API Provider** como **LiteLLM**.
   - Insira as seguintes configurações do LiteLLM:
     - **Base URL:** `http://litellm-service:4000`
     - **API Key:** `noop`
     - **Model:** `gpt-5.4-mini`
   - Clique em **Let's go!**  
     ![cline-welcome](../../../assets/images/cline-welcome.png)

3. **Teste o Cline:**
   - Teste sua configuração inserindo um prompt no Cline (por exemplo, peça para ele contar uma piada).
     ![cline-working](../../../assets/images/cline-working.png)

**Dica:**  
Se não receber uma resposta, verifique suas configurações de API ou peça ajuda ao seu SA!

{% include simple_next_nav.html %}

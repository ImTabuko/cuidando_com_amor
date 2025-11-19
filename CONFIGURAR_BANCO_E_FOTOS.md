# 🗄️ Configurar Banco de Dados e Fotos de Perfil

Este guia explica como configurar o MongoDB e habilitar o upload de fotos de perfil.

## 📋 Pré-requisitos

1. Conta no MongoDB Atlas (gratuita): https://www.mongodb.com/cloud/atlas
2. Backend deployado (Vercel, Render, etc.)
3. Acesso às variáveis de ambiente do seu servidor

---

## 🔧 Passo 1: Criar Banco de Dados MongoDB

### 1.1 Criar conta no MongoDB Atlas

1. Acesse: https://www.mongodb.com/cloud/atlas/register
2. Crie uma conta gratuita (Free Tier)
3. Preencha os dados e confirme o email

### 1.2 Criar Cluster

1. Após login, clique em **"Build a Database"**
2. Escolha o plano **FREE (M0)**
3. Escolha um provedor (AWS, Google Cloud, Azure)
4. Escolha uma região próxima ao Brasil (ex: `us-east-1`)
5. Clique em **"Create"**

### 1.3 Configurar Acesso

1. **Criar usuário do banco:**
   - Vá em **"Database Access"** (menu lateral)
   - Clique em **"Add New Database User"**
   - Escolha **"Password"** como método de autenticação
   - Crie um usuário e senha (anote bem!)
   - Permissões: **"Atlas admin"** ou **"Read and write to any database"**
   - Clique em **"Add User"**

2. **Configurar Network Access:**
   - Vá em **"Network Access"** (menu lateral)
   - Clique em **"Add IP Address"**
   - Para desenvolvimento: clique em **"Allow Access from Anywhere"** (0.0.0.0/0)
   - Para produção: adicione apenas os IPs do seu servidor
   - Clique em **"Confirm"**

### 1.4 Obter String de Conexão

1. Vá em **"Database"** (menu lateral)
2. Clique em **"Connect"** no seu cluster
3. Escolha **"Connect your application"**
4. Copie a **Connection String** (algo como):
   ```
   mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
5. **Substitua** `<username>` e `<password>` pelos dados do usuário criado
6. Adicione o nome do banco no final: `/cuidando?retryWrites=true&w=majority`

**Exemplo final:**
```
mongodb+srv://usuario:senha123@cluster0.xxxxx.mongodb.net/cuidando?retryWrites=true&w=majority
```

---

## 🚀 Passo 2: Configurar Backend

### 2.1 Deploy no Vercel (Recomendado)

1. **Conectar repositório:**
   - Acesse: https://vercel.com
   - Conecte seu repositório GitHub
   - Selecione a pasta `server` como raiz

2. **Configurar variáveis de ambiente:**
   - No projeto Vercel, vá em **Settings → Environment Variables**
   - Adicione:
     - **Nome:** `MONGODB_URI`
     - **Valor:** A string de conexão que você copiou
   - Clique em **Save**

3. **Fazer deploy:**
   - Vercel faz deploy automático ao fazer push no GitHub
   - Ou clique em **Deploy** manualmente

### 2.2 Deploy no Render

1. Acesse: https://render.com
2. Crie um novo **Web Service**
3. Conecte seu repositório GitHub
4. Configure:
   - **Build Command:** `cd server && npm install`
   - **Start Command:** `cd server && npm start`
   - **Environment:** `Node`
5. Adicione variável de ambiente:
   - **Key:** `MONGODB_URI`
   - **Value:** Sua string de conexão
6. Clique em **Create Web Service**

### 2.3 Testar Backend

Após o deploy, teste se está funcionando:

```bash
# Teste de health check
curl https://seu-backend.vercel.app/api/health

# Deve retornar:
# {"status":"ok","message":"Cuidando com Amor API"}
```

---

## 📸 Passo 3: Configurar Upload de Fotos

O sistema de fotos já está implementado! Funciona assim:

### 3.1 Como Funciona

1. **No registro:**
   - Usuário seleciona foto (galeria ou câmera)
   - Foto é convertida para base64
   - Enviada junto com os dados do registro
   - Salva no campo `photoUrl` do usuário

2. **Exibição:**
   - Se `photoUrl` começa com `http://` ou `https://` → mostra como URL
   - Se começa com `data:image/` → mostra como base64
   - Caso contrário → mostra ícone padrão

### 3.2 Endpoint de Upload

O backend já tem o endpoint para atualizar foto:

```
PUT /api/users/:id/photo
Body: { "photoUrl": "data:image/jpeg;base64,..." }
```

### 3.3 Testar Upload

1. Faça registro com foto
2. Verifique no MongoDB Atlas se o campo `photoUrl` foi salvo
3. A foto deve aparecer no perfil do usuário

---

## 🔍 Passo 4: Verificar se Está Funcionando

### 4.1 Verificar MongoDB

1. Acesse MongoDB Atlas
2. Vá em **"Database" → "Browse Collections"**
3. Deve aparecer o banco `cuidando` com:
   - Collection `users` (usuários)
   - Collection `matches` (matches)

### 4.2 Verificar Backend

```bash
# Listar usuários
curl https://seu-backend.vercel.app/api/users

# Deve retornar lista de usuários (pode estar vazia)
```

### 4.3 Verificar Fotos

1. Faça um registro com foto
2. Verifique no MongoDB se o campo `photoUrl` tem conteúdo
3. A foto deve aparecer no perfil

---

## 🐛 Solução de Problemas

### Erro: "MONGODB_URI não definida"

**Solução:**
- Verifique se a variável de ambiente está configurada no servidor
- Reinicie o servidor após adicionar a variável

### Erro: "Connection timeout"

**Solução:**
- Verifique se o IP está liberado no Network Access do MongoDB
- Para desenvolvimento, use `0.0.0.0/0` (permitir todos)

### Fotos não aparecem

**Solução:**
- Verifique se o `photoUrl` está sendo salvo no MongoDB
- Verifique se o formato está correto (`data:image/...`)
- Limite de tamanho: 10MB (configurado no backend)

### Backend não conecta ao MongoDB

**Solução:**
- Verifique a string de conexão (usuário e senha corretos)
- Verifique se o nome do banco está na URL (`/cuidando`)
- Verifique os logs do servidor para mais detalhes

---

## 📝 Resumo das URLs

Após configurar, você terá:

- **MongoDB Atlas:** https://cloud.mongodb.com
- **Backend API:** `https://seu-backend.vercel.app/api`
- **Health Check:** `https://seu-backend.vercel.app/api/health`

---

## ✅ Checklist

- [ ] Conta MongoDB Atlas criada
- [ ] Cluster criado e configurado
- [ ] Usuário do banco criado
- [ ] Network Access configurado
- [ ] String de conexão obtida
- [ ] Backend deployado
- [ ] Variável `MONGODB_URI` configurada
- [ ] Health check funcionando
- [ ] Teste de registro com foto realizado
- [ ] Fotos aparecendo nos perfis

---

## 🎉 Pronto!

Agora seu app está conectado ao banco de dados e pode salvar fotos de perfil!

Para mais ajuda, consulte:
- MongoDB Atlas Docs: https://docs.atlas.mongodb.com
- Vercel Docs: https://vercel.com/docs





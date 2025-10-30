# 🚀 Cuidando com Amor - API

API REST para o aplicativo Cuidando com Amor.

## 🔧 Tecnologias

- Node.js 18+
- Express.js
- MongoDB (Mongoose)
- CORS

## 📦 Instalação Local

```bash
npm install
npm start
```

Servidor rodará em: `http://localhost:3000`

## 🌐 Deploy no Vercel (GRÁTIS!)

Veja o arquivo `DEPLOY_VERCEL.md` na raiz do projeto para instruções completas.

### Resumo rápido:
1. Suba o código no GitHub
2. Conecte no Vercel
3. Configure `MONGODB_URI` nas variáveis de ambiente
4. Deploy automático! ✨

## 📚 Endpoints

### Health Check
- `GET /api/health` - Verifica se a API está online
- `GET /api/test` - Informações de teste

### Usuários
- `GET /api/users` - Lista usuários
  - Query params: `?userType=elderly` ou `?userType=caregiver`
  - Query params: `?city=São Paulo`
- `GET /api/users/:id` - Busca usuário por ID
- `POST /api/users` - Cria novo usuário

### Autenticação
- `POST /api/auth/login` - Login de usuário

### Matches
- `GET /api/matches` - Lista matches
- `POST /api/matches` - Cria novo match

## 🔐 Variáveis de Ambiente

```env
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/database
PORT=3000
```

## 📝 Estrutura de Dados

### Usuário (User)
```json
{
  "fullName": "string",
  "email": "string",
  "password": "string",
  "phone": "string",
  "cpf": "string",
  "street": "string",
  "neighborhood": "string",
  "city": "string",
  "state": "string",
  "userType": "elderly | caregiver",
  "photoUrl": "string",
  "birthDate": "date",
  "careNeeds": "string",
  "location": "string",
  "preferredTime": "string",
  "description": "string"
}
```

### Match
```json
{
  "elderlyId": "string",
  "caregiverId": "string",
  "status": "pending | accepted | rejected"
}
```

## 🎯 Próximos Passos

- [ ] Implementar autenticação JWT real
- [ ] Hash de senhas com bcrypt
- [ ] Validação de dados
- [ ] Paginação
- [ ] Upload de fotos
- [ ] Sistema de mensagens/chat

---

Desenvolvido com ❤️ para o TCC

const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const app = express();
app.use(cors());
app.use(express.json({ limit: '5mb' }));

// Conectar MongoDB - somente via variável de ambiente
const MONGODB_URI = process.env.MONGODB_URI;
if (!MONGODB_URI) {
  console.error('❌ Variável MONGODB_URI não definida. Configure no Render/ambiente.');
}

console.log('🔍 MONGODB_URI exists:', !!process.env.MONGODB_URI);
console.log('🔍 Connecting to MongoDB...');

if (MONGODB_URI && MONGODB_URI.includes('mongodb')) {
  mongoose.connect(MONGODB_URI, {
    dbName: 'cuidando',
    serverSelectionTimeoutMS: 30000, // 30 segundos
    socketTimeoutMS: 45000, // 45 segundos
    family: 4, // força IPv4 (evita timeouts em ambientes serverless)
  })
    .then(() => console.log('✅ Conectado ao MongoDB'))
    .catch(err => {
      console.log('❌ Erro MongoDB:', err.message);
      console.log('❌ Full error:', err);
    });
} else {
  console.log('❌ MONGODB_URI inválida ou não definida');
}

// Schema de Usuário
const userSchema = new mongoose.Schema({
  fullName: String,
  email: String,
  password: String,
  phone: String,
  cpf: String,
  street: String,
  neighborhood: String,
  city: String,
  state: String,
  userType: { type: String, enum: ['elderly', 'caregiver'] },
  photoUrl: String,
  birthDate: Date,
  careNeeds: String,
  location: String,
  preferredTime: String,
  description: String,
  createdAt: { type: Date, default: Date.now }
});

const User = mongoose.model('User', userSchema);

// Schema de Match
const matchSchema = new mongoose.Schema({
  elderlyId: String,
  caregiverId: String,
  status: { type: String, enum: ['pending', 'accepted', 'rejected'] },
  createdAt: { type: Date, default: Date.now }
});

const Match = mongoose.model('Match', matchSchema);

// Rota de Health Check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Cuidando com Amor API' });
});

// Rota de teste
app.get('/api/test', (req, res) => {
  res.json({ 
    message: 'API funcionando!',
    timestamp: new Date(),
    env: process.env.NODE_ENV || 'development'
  });
});

// GET - Listar usuários
// Paginação e ordenação: /api/users?page=1&limit=20&sort=createdAt:-1
app.get('/api/users', async (req, res) => {
  try {
    const { userType, city, page = 1, limit = 20, sort } = req.query;
    const query = {};
    
    if (userType) query.userType = userType;
    if (city) query.city = city;

    const sortObj = {};
    if (sort) {
      // exemplo: createdAt:-1 ou fullName:1
      const [field, dir] = String(sort).split(':');
      if (field) sortObj[field] = Number(dir) || 1;
    }

    const skip = (Number(page) - 1) * Number(limit);
    const [items, total] = await Promise.all([
      User.find(query).sort(sortObj).skip(skip).limit(Number(limit)),
      User.countDocuments(query)
    ]);

    res.json({ items, page: Number(page), limit: Number(limit), total });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET - Buscar usuário por ID
app.get('/api/users/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ error: 'Usuário não encontrado' });
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST - Criar usuário
app.post('/api/users', async (req, res) => {
  try {
    const newUser = new User(req.body);
    await newUser.save();
    res.status(201).json(newUser);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Auth com JWT
const JWT_SECRET = process.env.JWT_SECRET || 'change-this-secret';

// POST - Registro (hash de senha)
app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password, fullName, userType } = req.body;
    const exists = await User.findOne({ email });
    if (exists) return res.status(409).json({ error: 'E-mail já cadastrado' });

    const hashed = await bcrypt.hash(password, 10);
    const newUser = await User.create({ email, password: hashed, fullName, userType });
    res.status(201).json({ id: newUser._id });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// POST - Login (gera JWT)
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(401).json({ error: 'Credenciais inválidas' });

    const ok = await bcrypt.compare(password, user.password || '');
    if (!ok) return res.status(401).json({ error: 'Credenciais inválidas' });

    const token = jwt.sign({ sub: user._id }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Middleware de autenticação
function auth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) return res.status(401).json({ error: 'Token ausente' });
    const payload = jwt.verify(token, JWT_SECRET);
    req.userId = payload.sub;
    next();
  } catch {
    return res.status(401).json({ error: 'Token inválido' });
  }
}

// Exemplo de rota protegida
app.get('/api/me', auth, async (req, res) => {
  const me = await User.findById(req.userId).select('-password');
  res.json(me);
});

// Rota de seed (simples) - proteger com chave
app.post('/api/seed', async (req, res) => {
  try {
    const key = req.query.key;
    if (key !== (process.env.SEED_KEY || 'seed')) return res.status(403).json({ error: 'Forbidden' });
    const count = await User.countDocuments();
    if (count > 0) return res.json({ message: 'Já populado' });
    await User.insertMany([
      { fullName: 'João da Silva', email: 'joao@example.com', password: await bcrypt.hash('123456', 10), city: 'São Paulo', userType: 'elderly' },
      { fullName: 'Maria Souza', email: 'maria@example.com', password: await bcrypt.hash('123456', 10), city: 'Rio de Janeiro', userType: 'caregiver' }
    ]);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Alias GET para facilitar teste no navegador
app.get('/api/seed', async (req, res) => {
  try {
    const key = req.query.key;
    if (key !== (process.env.SEED_KEY || 'seed')) return res.status(403).json({ error: 'Forbidden' });
    const count = await User.countDocuments();
    if (count > 0) return res.json({ message: 'Já populado' });
    await User.insertMany([
      { fullName: 'João da Silva', email: 'joao@example.com', password: await bcrypt.hash('123456', 10), city: 'São Paulo', userType: 'elderly' },
      { fullName: 'Maria Souza', email: 'maria@example.com', password: await bcrypt.hash('123456', 10), city: 'Rio de Janeiro', userType: 'caregiver' }
    ]);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET - Matches
app.get('/api/matches', async (req, res) => {
  try {
    const matches = await Match.find();
    res.json(matches);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST - Criar match
app.post('/api/matches', async (req, res) => {
  try {
    const newMatch = new Match(req.body);
    await newMatch.save();
    res.status(201).json(newMatch);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// PUT - Atualizar status do match (aceitar/rejeitar)
app.put('/api/matches/:id', async (req, res) => {
  try {
    const { status } = req.body;
    const match = await Match.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true }
    );
    if (!match) return res.status(404).json({ error: 'Match não encontrado' });
    res.json(match);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server rodando na porta ${PORT}`);
  console.log(`📍 Acesse: http://localhost:${PORT}`);
  console.log(`🔗 Health: http://localhost:${PORT}/api/health`);
});

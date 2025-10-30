const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');

const app = express();
app.use(cors());
app.use(express.json());

// Conectar MongoDB
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb+srv://apiuser:senha123@cluster0.fykcpdl.mongodb.net/cuidando?retryWrites=true&w=majority';

console.log('🔍 MONGODB_URI exists:', !!process.env.MONGODB_URI);
console.log('🔍 Connecting to MongoDB...');

if (MONGODB_URI && MONGODB_URI.includes('mongodb')) {
  mongoose.connect(MONGODB_URI, {
    serverSelectionTimeoutMS: 30000, // 30 segundos
    socketTimeoutMS: 45000, // 45 segundos
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
app.get('/api/users', async (req, res) => {
  try {
    const { userType, city } = req.query;
    let query = {};
    
    if (userType) query.userType = userType;
    if (city) query.city = city;
    
    const users = await User.find(query);
    res.json(users);
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

// POST - Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    
    if (!user || user.password !== password) {
      return res.status(401).json({ error: 'Credenciais inválidas' });
    }
    
    res.json({ user, token: 'fake-token' });
  } catch (error) {
    res.status(500).json({ error: error.message });
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

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server rodando na porta ${PORT}`);
  console.log(`📍 Acesse: http://localhost:${PORT}`);
  console.log(`🔗 Health: http://localhost:${PORT}/api/health`);
});

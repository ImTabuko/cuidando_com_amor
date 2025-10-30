import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/match.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal() {
    // tenta carregar do backend; se falhar, usa mocks
    _loadFromApi().catchError((_) => _initializeSampleData());
  }

  // Dados em memória
  final List<User> _users = [];
  final List<Match> _matches = [];
  User? _currentUser;

  // Getters
  User? get currentUser => _currentUser;
  List<User> get allUsers => List.unmodifiable(_users);
  List<Match> get allMatches => List.unmodifiable(_matches);

  // Inicializar dados de exemplo
  void _initializeSampleData() {
    // Cuidadores de exemplo
    _users.addAll([
      CaregiverUser(
        id: 'caregiver1',
        fullName: 'Maria Silva',
        street: 'Rua das Flores, 123',
        neighborhood: 'Centro',
        city: 'São Paulo',
        state: 'SP',
        email: 'maria@email.com',
        cpf: '12345678901',
        password: '123456',
        phone: '(11) 99999-1111',
        description: 'Enfermeira, Técnico em Gerontologia',
        birthDate: DateTime(1985, 3, 15),
      ),
      CaregiverUser(
        id: 'caregiver2',
        fullName: 'João Santos',
        street: 'Av. Copacabana, 456',
        neighborhood: 'Copacabana',
        city: 'Rio de Janeiro',
        state: 'RJ',
        email: 'joao@email.com',
        cpf: '12345678902',
        password: '123456',
        phone: '(21) 99999-2222',
        birthDate: DateTime(1990, 7, 22),
        description: 'Técnico em Enfermagem, Fisioterapeuta',
      ),
      CaregiverUser(
        id: 'caregiver3',
        fullName: 'Ana Costa',
        street: 'Rua dos Inconfidentes, 789',
        neighborhood: 'Savassi',
        city: 'Belo Horizonte',
        state: 'MG',
        email: 'ana@email.com',
        cpf: '12345678903',
        password: '123456',
        phone: '(31) 99999-3333',
        birthDate: DateTime(1988, 11, 8),
        description: 'Cuidador(a) de Idosos, Experiência prática (sem formação formal)',
      ),
    ]);

    // Idosos de exemplo
    _users.addAll([
      ElderlyUser(
        id: 'elderly1',
        fullName: 'José Oliveira',
        street: 'Av. Paulista, 1000',
        neighborhood: 'Bela Vista',
        city: 'São Paulo',
        state: 'SP',
        cpf: '98765432101',
        email: 'jose@email.com', // Com email
        password: '123456',
        phone: '(11) 88888-1111',
        birthDate: DateTime(1950, 5, 10),
        careNeeds: 'Medicação e controle de remédios, Acompanhamento médico',
        location: 'Casa',
        preferredTime: 'Manhã',
      ),
      ElderlyUser(
        id: 'elderly2',
        fullName: 'Rosa Fernandes',
        street: 'Rua Atlântica, 300',
        neighborhood: 'Copacabana',
        city: 'Rio de Janeiro',
        state: 'RJ',
        cpf: '98765432102',
        // email: null, // Sem email - login apenas por telefone
        password: '123456',
        phone: '(21) 88888-2222',
        birthDate: DateTime(1945, 9, 18),
        careNeeds: 'Fisioterapia domiciliar, Auxílio na locomoção',
        location: 'Casa',
        preferredTime: 'Tarde',
      ),
      ElderlyUser(
        id: 'elderly3',
        fullName: 'Carlos Mendes',
        street: 'Av. Afonso Pena, 500',
        neighborhood: 'Centro',
        city: 'Belo Horizonte',
        state: 'MG',
        cpf: '98765432103',
        // email: null, // Sem email - login apenas por telefone
        password: '123456',
        phone: '(31) 88888-3333',
        birthDate: DateTime(1955, 12, 3),
        careNeeds: 'Companhia e conversa, Cuidados domésticos básicos',
        location: 'Hospital',
        preferredTime: 'Noite',
      ),
    ]);
  }

  // ------------------- Integração simples com a API -------------------
  static const String _baseUrl = 'https://cuidando-com-amor.onrender.com/api';

  Future<void> _loadFromApi() async {
    final res = await http.get(Uri.parse('$_baseUrl/users'));
    if (res.statusCode != 200) throw Exception('Falha ao carregar');
    final body = json.decode(res.body);
    final List data = body is Map && body['items'] is List ? body['items'] : (body as List);
    if (_users.isNotEmpty) return; // já populado
    for (final item in data) {
      final type = (item['userType'] ?? '').toString();
      if (type == 'caregiver') {
        _users.add(CaregiverUser(
          id: (item['_id'] ?? item['id'] ?? '').toString(),
          fullName: (item['fullName'] ?? 'Sem nome').toString(),
          street: (item['street'] ?? '').toString(),
          neighborhood: (item['neighborhood'] ?? '').toString(),
          city: (item['city'] ?? '').toString(),
          state: (item['state'] ?? '').toString(),
          email: (item['email'] ?? 'no@email.com').toString(),
          cpf: (item['cpf'] ?? '00000000000').toString(),
          password: (item['password'] ?? '123456').toString(),
          phone: (item['phone'] ?? '').toString(),
          description: (item['description'] ?? '').toString(),
          birthDate: DateTime.tryParse(item['birthDate']?.toString() ?? '') ?? DateTime(1990,1,1),
          photoUrl: item['photoUrl']?.toString(),
        ));
      } else if (type == 'elderly') {
        _users.add(ElderlyUser(
          id: (item['_id'] ?? item['id'] ?? '').toString(),
          fullName: (item['fullName'] ?? 'Sem nome').toString(),
          street: (item['street'] ?? '').toString(),
          neighborhood: (item['neighborhood'] ?? '').toString(),
          city: (item['city'] ?? '').toString(),
          state: (item['state'] ?? '').toString(),
          cpf: (item['cpf'] ?? '00000000000').toString(),
          email: item['email']?.toString(),
          password: (item['password'] ?? '123456').toString(),
          phone: (item['phone'] ?? '').toString(),
          birthDate: DateTime.tryParse(item['birthDate']?.toString() ?? '') ?? DateTime(1950,1,1),
          careNeeds: (item['careNeeds'] ?? '').toString(),
          location: (item['location'] ?? '').toString(),
          preferredTime: (item['preferredTime'] ?? '').toString(),
          photoUrl: item['photoUrl']?.toString(),
        ));
      }
    }
    if (_users.isEmpty) {
      // se vazio, usa mocks para não quebrar telas
      _initializeSampleData();
    }
  }

  // Autenticação
  bool login(String emailOrPhone, String password) {
    try {
      final user = _users.firstWhere(
        (user) => (_getUserEmail(user) == emailOrPhone || _getUserPhone(user) == emailOrPhone) && 
                  _getUserPassword(user) == password,
      );
      _currentUser = user;
      return true;
    } catch (e) {
      return false;
    }
  }

  bool loginByPhone(String phone, String password) {
    try {
      final user = _users.firstWhere(
        (user) => _getUserPhone(user) == phone && _getUserPassword(user) == password,
      );
      _currentUser = user;
      return true;
    } catch (e) {
      return false;
    }
  }

  bool registerElderly({
    required String fullName,
    required String street,
    required String neighborhood,
    required String city,
    required String state,
    String? email, // Email opcional para idosos
    required String cpf,
    required String password,
    required String phone,
    required DateTime birthDate,
    required String careNeeds,
    required String location,
    required String preferredTime,
    String? photoUrl,
  }) {
    try {
      // envia para API; se falhar, cai no modo local abaixo
      _postUserToApi({
        'fullName': fullName,
        'street': street,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
        'email': email,
        'cpf': cpf,
        'password': password,
        'phone': phone,
        'birthDate': birthDate.toIso8601String(),
        'careNeeds': careNeeds,
        'location': location,
        'preferredTime': preferredTime,
        'userType': 'elderly',
        'photoUrl': photoUrl != null ? _encodeFileToDataUri(photoUrl) : null,
      });
    } catch (_) {}

    try {
      final elderly = ElderlyUser(
        id: _generateId(),
        fullName: fullName,
        street: street,
        neighborhood: neighborhood,
        city: city,
        state: state,
        email: email,
        cpf: cpf,
        password: password,
        phone: phone,
        birthDate: birthDate,
        careNeeds: careNeeds,
        location: location,
        preferredTime: preferredTime,
        photoUrl: photoUrl,
      );
      _users.add(elderly);
      _currentUser = elderly;
      return true;
    } catch (e) {
      return false;
    }
  }

  bool registerCaregiver({
    required String fullName,
    required String street,
    required String neighborhood,
    required String city,
    required String state,
    required String email,
    required String cpf,
    required String password,
    required String phone,
    required DateTime birthDate,
    required String description,
    String? photoUrl,
  }) {
    try {
      _postUserToApi({
        'fullName': fullName,
        'street': street,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
        'email': email,
        'cpf': cpf,
        'password': password,
        'phone': phone,
        'birthDate': birthDate.toIso8601String(),
        'description': description,
        'userType': 'caregiver',
        'photoUrl': photoUrl != null ? _encodeFileToDataUri(photoUrl) : null,
      });
    } catch (_) {}

    try {
      final caregiver = CaregiverUser(
        id: _generateId(),
        fullName: fullName,
        street: street,
        neighborhood: neighborhood,
        city: city,
        state: state,
        email: email,
        cpf: cpf,
        password: password,
        phone: phone,
        birthDate: birthDate,
        description: description,
        photoUrl: photoUrl,
      );
      _users.add(caregiver);
      _currentUser = caregiver;
      return true;
    } catch (e) {
      return false;
    }
  }

  // util: envia usuário para API (ignora respostas/erros)
  Future<void> _postUserToApi(Map<String, dynamic?> data) async {
    final body = json.encode(data..removeWhere((k, v) => v == null));
    await http
        .post(Uri.parse('$_baseUrl/users'), headers: {'Content-Type': 'application/json; charset=utf-8'}, body: body)
        .timeout(const Duration(seconds: 20));
  }

  // util: converte caminho de arquivo em data URI base64
  String _encodeFileToDataUri(String path) {
    try {
      final file = File(path);
      final bytes = file.readAsBytesSync();
      final b64 = base64Encode(bytes);
      return 'data:image/jpeg;base64,' + b64;
    } catch (_) {
      return path; // fallback
    }
  }

  void logout() {
    _currentUser = null;
  }

  // Buscar usuários filtrados por cidade/bairro
  List<CaregiverUser> getAvailableCaregivers() {
    final allCaregivers = _users.whereType<CaregiverUser>().toList();
    
    // Se não há usuário logado, retornar lista vazia
    if (_currentUser == null) return [];
    
    // Pegar endereço do usuário atual
    final currentUserCity = _currentUser!.city;
    final currentUserNeighborhood = _currentUser!.neighborhood;
    final currentUserState = _currentUser!.state;
    
    // Priorizar: mesmo bairro > mesma cidade > mesmo estado
    final sameNeighborhood = allCaregivers.where((caregiver) => 
      caregiver.neighborhood == currentUserNeighborhood && 
      caregiver.city == currentUserCity
    ).toList();
    
    if (sameNeighborhood.isNotEmpty) return sameNeighborhood;
    
    final sameCity = allCaregivers.where((caregiver) => 
      caregiver.city == currentUserCity
    ).toList();
    
    if (sameCity.isNotEmpty) return sameCity;
    
    final sameState = allCaregivers.where((caregiver) => 
      caregiver.state == currentUserState
    ).toList();
    
    // Se não há ninguém, retornar alguns para não deixar vazio
    return sameState.take(10).toList();
  }

  List<ElderlyUser> getAvailableElderlies() {
    final allElderlies = _users.whereType<ElderlyUser>().toList();
    
    // Se não há usuário logado, retornar lista vazia
    if (_currentUser == null) return [];
    
    // Pegar endereço do usuário atual
    final currentUserCity = _currentUser!.city;
    final currentUserNeighborhood = _currentUser!.neighborhood;
    final currentUserState = _currentUser!.state;
    
    // Priorizar: mesmo bairro > mesma cidade > mesmo estado
    final sameNeighborhood = allElderlies.where((elderly) => 
      elderly.neighborhood == currentUserNeighborhood && 
      elderly.city == currentUserCity
    ).toList();
    
    if (sameNeighborhood.isNotEmpty) return sameNeighborhood;
    
    final sameCity = allElderlies.where((elderly) => 
      elderly.city == currentUserCity
    ).toList();
    
    if (sameCity.isNotEmpty) return sameCity;
    
    final sameState = allElderlies.where((elderly) => 
      elderly.state == currentUserState
    ).toList();
    
    // Se não há ninguém, retornar alguns para não deixar vazio
    return sameState.take(10).toList();
  }

  // Matches
  List<Match> getMatchesForCurrentUser() {
    if (_currentUser == null) return [];
    
    return _matches.where((match) => 
      match.elderlyId == _currentUser!.id || 
      match.caregiverId == _currentUser!.id
    ).toList();
  }

  Match createMatch(String elderlyId, String caregiverId) {
    final match = Match(
      matchId: _generateId(),
      elderlyId: elderlyId,
      caregiverId: caregiverId,
      status: MatchStatus.pending,
      dataMatch: DateTime.now(),
    );

    _matches.add(match);
    return match;
  }

  void acceptMatch(String matchId) {
    final match = _matches.firstWhere((m) => m.matchId == matchId);
    final index = _matches.indexOf(match);
    _matches[index] = Match(
      matchId: match.matchId,
      elderlyId: match.elderlyId,
      caregiverId: match.caregiverId,
      status: MatchStatus.accepted,
      dataMatch: match.dataMatch,
    );
  }

  void rejectMatch(String matchId) {
    final match = _matches.firstWhere((m) => m.matchId == matchId);
    final index = _matches.indexOf(match);
    _matches[index] = Match(
      matchId: match.matchId,
      elderlyId: match.elderlyId,
      caregiverId: match.caregiverId,
      status: MatchStatus.rejected,
      dataMatch: match.dataMatch,
    );
  }

  User? getUserById(String userId) {
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  // Métodos auxiliares
  String? _getUserEmail(User user) {
    if (user is ElderlyUser) {
      return user.email; // Pode ser null
    } else if (user is CaregiverUser) {
      return user.email;
    }
    throw Exception('Tipo de usuário não suportado');
  }

  String _getUserPhone(User user) {
    if (user is ElderlyUser) {
      return user.phone;
    } else if (user is CaregiverUser) {
      return user.phone;
    }
    throw Exception('Tipo de usuário não suportado');
  }

  String _getUserPassword(User user) {
    if (user is ElderlyUser) {
      return user.password;
    } else if (user is CaregiverUser) {
      return user.password;
    }
    throw Exception('Tipo de usuário não suportado');
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (DateTime.now().microsecond % 1000).toString();
  }
}

import '../models/user.dart';
import '../models/match.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal() {
    _initializeSampleData();
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
      // Verificar se email já existe (apenas se fornecido)
      if (email != null && _users.any((user) => _getUserEmail(user) == email)) {
        return false;
      }

      // Verificar se telefone já existe
      if (_users.any((user) => _getUserPhone(user) == phone)) {
        return false;
      }

      final elderly = ElderlyUser(
        id: _generateId(),
        fullName: fullName,
        street: street,
        neighborhood: neighborhood,
        city: city,
        state: state,
        email: email, // Pode ser null
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
      // Verificar se email já existe
      if (_users.any((user) => _getUserEmail(user) == email)) {
        return false;
      }

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

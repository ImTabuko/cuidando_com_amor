import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/match.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Dados em memória
  final List<User> _users = [];
  final List<Match> _matches = [];
  User? _currentUser;
  bool _isInitialized = false;

  // Getters
  User? get currentUser => _currentUser;
  List<User> get allUsers => List.unmodifiable(_users);
  List<Match> get allMatches => List.unmodifiable(_matches);


  // ------------------- Integração com a API -------------------
  static const String _baseUrl = 'https://cuidando-com-amor-ssud.vercel.app/api';

  // Inicializar carregando dados do servidor
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _loadUsersFromApi();
      await _loadMatchesFromApi();
    } catch (e) {
      // Continua mesmo se falhar - modo offline
      print('Erro na inicialização: $e');
    }
    _isInitialized = true;
  }

  // Método público para recarregar usuários (usado após atualizações)
  Future<void> reloadUsersFromApi() async {
    await _loadUsersFromApi();
  }
  
  Future<void> _loadUsersFromApi() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/users')).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('⚠️ Timeout ao carregar usuários');
          throw TimeoutException('Timeout', const Duration(seconds: 3));
        },
      );
      if (res.statusCode != 200) {
        print('⚠️ Servidor retornou status ${res.statusCode}');
        return; // Continua sem dados do servidor
      }
      
      final body = json.decode(res.body);
      final List data = body is Map && body['items'] is List ? body['items'] : (body as List);
      
      // Criar mapa de usuários existentes por ID para evitar duplicação
      final existingUsersMap = <String, User>{};
      for (final user in _users) {
        existingUsersMap[user.id] = user;
      }
      
      // Processar cada item da API
      for (final item in data) {
        final userId = (item['_id'] ?? item['id'] ?? '').toString();
        if (userId.isEmpty) continue; // Pular se não tiver ID
        
        final type = (item['userType'] ?? '').toString();
        final photoUrl = item['photoUrl']?.toString();
        
        // Se o usuário já existe, atualizar (especialmente photoUrl)
        if (existingUsersMap.containsKey(userId)) {
          final existingUser = existingUsersMap[userId]!;
          // Atualizar photoUrl se fornecido
          if (photoUrl != null && photoUrl.isNotEmpty) {
            existingUser.photoUrl = photoUrl;
          }
          continue; // Pular criação, já existe
        }
        
        // Criar novo usuário apenas se não existir
        if (type == 'caregiver') {
          _users.add(CaregiverUser(
            id: userId,
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
            photoUrl: photoUrl,
          ));
        } else if (type == 'elderly') {
          _users.add(ElderlyUser(
            id: userId,
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
            photoUrl: photoUrl,
          ));
        }
      }
    } catch (e) {
      // Se falhar, continua sem dados do servidor (modo offline)
      print('Erro ao carregar usuários: $e');
      // Não lança exceção - permite que o app continue funcionando
    }
  }

  Future<void> _loadMatchesFromApi() async {
    await reloadMatchesFromApi();
  }

  // Método público para recarregar matches do servidor
  Future<void> reloadMatchesFromApi() async {
    try {
      print('📥 Carregando matches do backend...');
      final res = await http.get(Uri.parse('$_baseUrl/matches')).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Timeout ao carregar matches');
          throw TimeoutException('Timeout', const Duration(seconds: 5));
        },
      );
      if (res.statusCode == 200) {
        final List data = json.decode(res.body) as List;
        print('📊 Matches recebidos do backend: ${data.length}');
        
        // Criar mapa de matches existentes por ID
        final existingMatchesMap = <String, Match>{};
        for (final match in _matches) {
          existingMatchesMap[match.matchId] = match;
        }
        
        // Limpar lista e recriar com dados do servidor
        _matches.clear();
        
        for (final item in data) {
          MatchStatus status;
          switch (item['status']) {
            case 'accepted':
              status = MatchStatus.accepted;
              break;
            case 'rejected':
              status = MatchStatus.rejected;
              break;
            default:
              status = MatchStatus.pending;
          }
          
          final matchId = (item['_id'] ?? item['id'] ?? '').toString();
          final elderlyId = (item['elderlyId'] ?? '').toString();
          final caregiverId = (item['caregiverId'] ?? '').toString();
          
          // Converter createdBy do backend
          MatchCreatedBy? matchCreatedBy;
          final createdByStr = item['createdBy']?.toString();
          if (createdByStr == 'elderly') {
            matchCreatedBy = MatchCreatedBy.elderly;
          } else if (createdByStr == 'caregiver') {
            matchCreatedBy = MatchCreatedBy.caregiver;
          }
          
          print('  - Match: $matchId, Elderly: $elderlyId, Caregiver: $caregiverId, Status: $status, CreatedBy: $matchCreatedBy');
          
          // Usar match existente se disponível, senão criar novo
          final existingMatch = existingMatchesMap[matchId];
          if (existingMatch != null) {
            // Atualizar status do match existente
            existingMatch.status = status;
            if (matchCreatedBy != null) {
              existingMatch.createdBy = matchCreatedBy;
            }
            _matches.add(existingMatch);
          } else {
            _matches.add(Match(
              matchId: matchId,
              elderlyId: elderlyId,
              caregiverId: caregiverId,
              status: status,
              dataMatch: DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? DateTime.now(),
              createdBy: matchCreatedBy,
            ));
          }
        }
        print('✅ Total de matches carregados: ${_matches.length}');
      } else {
        print('⚠️ Backend retornou status ${res.statusCode}');
      }
    } catch (e) {
      // Se falhar ao carregar matches, continua sem eles
      print('❌ Erro ao carregar matches: $e');
    }
  }

  // Autenticação
  Future<bool> login(String emailOrPhone, String password) async {
    try {
      final user = _users.where(
        (user) => (_getUserEmail(user) == emailOrPhone || _getUserPhone(user) == emailOrPhone) && 
                  _getUserPassword(user) == password,
      ).firstOrNull;
      
      if (user == null) return false;
      
      _currentUser = user;
      
      // Salvar ID do usuário para login automático
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.id);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> loginByPhone(String phone, String password) async {
    try {
      final user = _users.where(
        (user) => _getUserPhone(user) == phone && _getUserPassword(user) == password,
      ).firstOrNull;
      
      if (user == null) return false;
      
      _currentUser = user;
      
      // Salvar ID do usuário para login automático
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.id);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Tentar login automático
  Future<bool> autoLogin() async {
    try {
      // Timeout no SharedPreferences (pode ser lento no web)
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          print('⚠️ Timeout ao acessar SharedPreferences');
          throw TimeoutException('SharedPreferences timeout', const Duration(seconds: 2));
        },
      );
      
      final userId = prefs.getString('userId');
      if (userId == null || userId.isEmpty) {
        return false;
      }
      
      // Tentar encontrar o usuário na lista atual
      var user = _users.where((u) => u.id == userId).firstOrNull;
      if (user != null) {
        _currentUser = user;
        return true;
      }
      
      // Usuário não encontrado na lista, tentar recarregar do servidor
      print('⚠️ Usuário $userId não encontrado na lista, recarregando do servidor...');
      try {
        await _loadUsersFromApi();
        // Tentar novamente após recarregar
        user = _users.where((u) => u.id == userId).firstOrNull;
        if (user != null) {
          _currentUser = user;
          return true;
        } else {
          print('⚠️ Usuário $userId ainda não encontrado após recarregar');
          return false;
        }
      } catch (e2) {
        print('⚠️ Erro ao recarregar usuários: $e2');
        return false;
      }
    } catch (e) {
      print('⚠️ Erro no autoLogin: $e');
      return false;
    }
  }

  Future<bool> registerElderly({
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
  }) async {
    try {
      // Tentar enviar para API primeiro
      try {
        await _postUserToApi({
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
          'photoUrl': photoUrl, // Já vem em base64 do registro
        });
      } catch (e) {
        print('⚠️ Erro ao enviar usuário para API: $e');
        // Continua para criar localmente
      }

      // Criar localmente (mesmo se API falhar)
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
      
      // Verificar se já existe antes de adicionar
      if (!_users.any((u) => u.id == elderly.id)) {
        _users.add(elderly);
      }
      _currentUser = elderly;
      return true;
    } catch (e) {
      print('❌ Erro ao registrar idoso: $e');
      return false;
    }
  }

  Future<bool> registerCaregiver({
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
  }) async {
    try {
      // Tentar enviar para API primeiro
      try {
        await _postUserToApi({
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
          'photoUrl': photoUrl, // Já vem em base64 do registro
        });
      } catch (e) {
        print('⚠️ Erro ao enviar usuário para API: $e');
        // Continua para criar localmente
      }

      // Criar localmente (mesmo se API falhar)
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
      
      // Verificar se já existe antes de adicionar
      if (!_users.any((u) => u.id == caregiver.id)) {
        _users.add(caregiver);
      }
      _currentUser = caregiver;
      return true;
    } catch (e) {
      print('❌ Erro ao registrar cuidador: $e');
      return false;
    }
  }

  // util: envia usuário para API (ignora respostas/erros)
  Future<void> _postUserToApi(Map<String, dynamic> data) async {
    try {
      // Remover valores null, mas manter strings vazias e photoUrl
      final cleanData = Map<String, dynamic>.from(data);
      cleanData.removeWhere((k, v) => v == null && k != 'photoUrl');
      
      final body = json.encode(cleanData);
      print('📤 Enviando usuário para API (photoUrl: ${data['photoUrl'] != null ? 'presente (${data['photoUrl'].toString().length} chars)' : 'ausente'})');
      
      final response = await http
          .post(
            Uri.parse('$_baseUrl/users'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: body,
          )
          .timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Usuário criado no backend com sucesso');
        // Recarregar usuários do backend para incluir o novo usuário
        _loadUsersFromApi().catchError((e) {
          print('⚠️ Erro ao recarregar usuários após criação: $e');
        });
      } else {
        print('⚠️ Servidor retornou status ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Erro ao enviar usuário para API: $e');
      // Não lança exceção - permite que o app continue funcionando localmente
    }
  }


  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  // Buscar usuários filtrados por cidade/bairro
  List<CaregiverUser> getAvailableCaregivers() {
    final allCaregivers = _users.whereType<CaregiverUser>().toList();
    
    // Se não há usuário logado, retornar lista vazia
    if (_currentUser == null) return [];
    
    // Filtrar para não mostrar o próprio usuário
    final filteredCaregivers = allCaregivers.where((caregiver) => 
      caregiver.id != _currentUser!.id
    ).toList();
    
    // Pegar endereço do usuário atual
    final currentUserCity = _currentUser!.city;
    final currentUserNeighborhood = _currentUser!.neighborhood;
    final currentUserState = _currentUser!.state;
    
    // Priorizar: mesmo bairro > mesma cidade > mesmo estado
    final sameNeighborhood = filteredCaregivers.where((caregiver) => 
      caregiver.neighborhood == currentUserNeighborhood && 
      caregiver.city == currentUserCity
    ).toList();
    
    if (sameNeighborhood.isNotEmpty) return sameNeighborhood;
    
    final sameCity = filteredCaregivers.where((caregiver) => 
      caregiver.city == currentUserCity
    ).toList();
    
    if (sameCity.isNotEmpty) return sameCity;
    
    final sameState = filteredCaregivers.where((caregiver) => 
      caregiver.state == currentUserState
    ).toList();
    
    // Se não há ninguém, retornar alguns para não deixar vazio
    return sameState.take(10).toList();
  }

  List<ElderlyUser> getAvailableElderlies() {
    final allElderlies = _users.whereType<ElderlyUser>().toList();
    
    // Se não há usuário logado, retornar lista vazia
    if (_currentUser == null) return [];
    
    // Filtrar para não mostrar o próprio usuário
    final filteredElderlies = allElderlies.where((elderly) => 
      elderly.id != _currentUser!.id
    ).toList();
    
    // Pegar endereço do usuário atual
    final currentUserCity = _currentUser!.city;
    final currentUserNeighborhood = _currentUser!.neighborhood;
    final currentUserState = _currentUser!.state;
    
    // Priorizar: mesmo bairro > mesma cidade > mesmo estado
    final sameNeighborhood = filteredElderlies.where((elderly) => 
      elderly.neighborhood == currentUserNeighborhood && 
      elderly.city == currentUserCity
    ).toList();
    
    if (sameNeighborhood.isNotEmpty) return sameNeighborhood;
    
    final sameCity = filteredElderlies.where((elderly) => 
      elderly.city == currentUserCity
    ).toList();
    
    if (sameCity.isNotEmpty) return sameCity;
    
    final sameState = filteredElderlies.where((elderly) => 
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

  // Verificar se existe match aceito entre dois usuários
  bool hasAcceptedMatch(String elderlyId, String caregiverId) {
    return _matches.any((match) =>
      ((match.elderlyId == elderlyId && match.caregiverId == caregiverId) ||
       (match.elderlyId == caregiverId && match.caregiverId == elderlyId)) &&
      match.status == MatchStatus.accepted
    );
  }

  // Obter match existente entre dois usuários (qualquer status)
  Match? getExistingMatch(String elderlyId, String caregiverId) {
    try {
      return _matches.where((match) =>
        (match.elderlyId == elderlyId && match.caregiverId == caregiverId) ||
        (match.elderlyId == caregiverId && match.caregiverId == elderlyId)
      ).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  Future<Match> createMatch(String elderlyId, String caregiverId, {MatchCreatedBy? createdBy}) async {
    // Tentar criar no backend PRIMEIRO (backend verifica duplicatas)
    try {
      print('📤 Criando match no backend: Elderly=$elderlyId, Caregiver=$caregiverId, CreatedBy=${createdBy?.toString()}');
      final response = await http.post(
        Uri.parse('$_baseUrl/matches'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'elderlyId': elderlyId,
          'caregiverId': caregiverId,
          'status': 'pending',
          'createdBy': createdBy?.toString().split('.').last ?? 'caregiver', // 'elderly' ou 'caregiver'
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Match criado/retornado do backend: ${data['_id']}');
        
        // Converter status do backend
        MatchStatus status;
        switch (data['status']) {
          case 'accepted':
            status = MatchStatus.accepted;
            break;
          case 'rejected':
            status = MatchStatus.rejected;
            break;
          default:
            status = MatchStatus.pending;
        }
        
        final matchId = (data['_id'] ?? data['id'] ?? '').toString();
        
        // Converter createdBy do backend
        MatchCreatedBy? matchCreatedBy;
        final createdByStr = data['createdBy']?.toString();
        if (createdByStr == 'elderly') {
          matchCreatedBy = MatchCreatedBy.elderly;
        } else if (createdByStr == 'caregiver') {
          matchCreatedBy = MatchCreatedBy.caregiver;
        }
        
        // Verificar se já existe localmente
        final existingMatchIndex = _matches.indexWhere((m) => m.matchId == matchId);
        if (existingMatchIndex != -1) {
          // Atualizar status do match existente
          _matches[existingMatchIndex].status = status;
          if (matchCreatedBy != null) {
            _matches[existingMatchIndex].createdBy = matchCreatedBy;
          }
          return _matches[existingMatchIndex];
        } else {
          // Match não existe localmente, criar novo
          final backendMatch = Match(
            matchId: matchId,
            elderlyId: elderlyId,
            caregiverId: caregiverId,
            status: status,
            dataMatch: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
            createdBy: matchCreatedBy ?? createdBy, // Usar do backend ou do parâmetro
          );
          _matches.add(backendMatch);
          return backendMatch;
        }
      } else if (response.statusCode == 400) {
        // Backend retornou erro (ex: match aceito já existe)
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Não é possível criar o match');
      } else {
        print('⚠️ Backend retornou status ${response.statusCode}');
        throw Exception('Backend retornou status ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao criar match no backend: $e');
      
      // Verificar se já existe localmente antes de criar novo
      final existingMatchIndex = _matches.indexWhere(
        (m) => (m.elderlyId == elderlyId && m.caregiverId == caregiverId) ||
               (m.elderlyId == caregiverId && m.caregiverId == elderlyId),
      );
      if (existingMatchIndex != -1) {
        print('⚠️ Match já existe localmente: ${_matches[existingMatchIndex].matchId}');
        return _matches[existingMatchIndex];
      } else {
        // Não existe, criar localmente
        final match = Match(
          matchId: _generateId(),
          elderlyId: elderlyId,
          caregiverId: caregiverId,
          status: MatchStatus.pending,
          dataMatch: DateTime.now(),
          createdBy: createdBy,
        );
        print('💾 Adicionando match localmente: ${match.matchId}');
        _matches.add(match);
        return match;
      }
    }
  }

  // Método unificado para atualizar status do match
  Future<Match?> updateMatchStatus(String matchId, MatchStatus newStatus) async {
    try {
      // Verificar se match existe localmente
      var matchIndex = _matches.indexWhere((m) => m.matchId == matchId);
      if (matchIndex == -1) {
        // Match não encontrado localmente, recarregar do servidor
        print('⚠️ Match não encontrado localmente, recarregando do servidor...');
        await reloadMatchesFromApi();
        matchIndex = _matches.indexWhere((m) => m.matchId == matchId);
        if (matchIndex == -1) {
          throw Exception('Match não encontrado: $matchId');
        }
      }
      
      final match = _matches[matchIndex];
      
      // Atualizar no backend PRIMEIRO
      try {
        final response = await _updateMatchOnServer(matchId, newStatus);
        print('✅ Match atualizado no backend: $matchId -> $newStatus');
        
        // Atualizar com dados do servidor se disponível
        if (response != null) {
          MatchStatus serverStatus;
          switch (response['status']) {
            case 'accepted':
              serverStatus = MatchStatus.accepted;
              break;
            case 'rejected':
              serverStatus = MatchStatus.rejected;
              break;
            default:
              serverStatus = MatchStatus.pending;
          }
          match.status = serverStatus;
        } else {
          // Se não recebeu resposta, atualizar localmente
          if (newStatus == MatchStatus.accepted) {
            match.accept();
          } else if (newStatus == MatchStatus.rejected) {
            match.reject();
          }
        }
      } catch (e) {
        print('❌ Erro ao atualizar match no backend: $e');
        // Atualizar localmente mesmo se falhar no backend
        if (newStatus == MatchStatus.accepted) {
          match.accept();
        } else if (newStatus == MatchStatus.rejected) {
          match.reject();
        }
      }
      
      // Recarregar matches do servidor para garantir sincronização
      await reloadMatchesFromApi();
      
      // Retornar match atualizado
      final finalMatchIndex = _matches.indexWhere((m) => m.matchId == matchId);
      return finalMatchIndex != -1 ? _matches[finalMatchIndex] : match;
    } catch (e) {
      throw Exception('Erro ao atualizar match: $e');
    }
  }

  // Método auxiliar para atualizar no servidor
  Future<Map<String, dynamic>?> _updateMatchOnServer(String matchId, MatchStatus status) async {
    final statusString = status == MatchStatus.accepted ? 'accepted' : 
                        status == MatchStatus.rejected ? 'rejected' : 'pending';
    
    final response = await http.put(
      Uri.parse('$_baseUrl/matches/$matchId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': statusString}),
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Servidor retornou status ${response.statusCode}');
    }
  }

  // Métodos de conveniência (mantidos para compatibilidade)
  Future<void> acceptMatch(String matchId) async {
    await updateMatchStatus(matchId, MatchStatus.accepted);
  }

  Future<void> rejectMatch(String matchId) async {
    await updateMatchStatus(matchId, MatchStatus.rejected);
  }

  User? getUserById(String userId) {
    return _users.where((user) => user.id == userId).firstOrNull;
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

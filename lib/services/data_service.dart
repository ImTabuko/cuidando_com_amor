import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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


  // ------------------- Integração simples com a API -------------------
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
      
      // Não limpar completamente - apenas atualizar/adição
      final existingIds = _users.map((u) => u.id).toSet();
      
    for (final item in data) {
      final userId = (item['_id'] ?? item['id'] ?? '').toString();
      final type = (item['userType'] ?? '').toString();
      final photoUrl = item['photoUrl']?.toString();
      
      // Se o usuário já existe, atualizar (especialmente photoUrl)
      if (existingIds.contains(userId)) {
        try {
          final existingUser = _users.firstWhere((u) => u.id == userId);
          existingUser.photoUrl = photoUrl;
          continue; // Pular criação, já atualizou
        } catch (_) {
          // Usuário não encontrado, continuar para criar
        }
      }
      
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
      final res = await http.get(Uri.parse('$_baseUrl/matches')).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('⚠️ Timeout ao carregar matches');
          throw TimeoutException('Timeout', const Duration(seconds: 3));
        },
      );
      if (res.statusCode == 200) {
        final List data = json.decode(res.body) as List;
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
          
          _matches.add(Match(
            matchId: (item['_id'] ?? item['id'] ?? '').toString(),
            elderlyId: (item['elderlyId'] ?? '').toString(),
            caregiverId: (item['caregiverId'] ?? '').toString(),
            status: status,
            dataMatch: DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? DateTime.now(),
          ));
        }
      }
    } catch (e) {
      // Se falhar ao carregar matches, continua sem eles
      print('Erro ao carregar matches: $e');
    }
  }

  // Autenticação
  Future<bool> login(String emailOrPhone, String password) async {
    try {
      final user = _users.firstWhere(
        (user) => (_getUserEmail(user) == emailOrPhone || _getUserPhone(user) == emailOrPhone) && 
                  _getUserPassword(user) == password,
      );
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
      final user = _users.firstWhere(
        (user) => _getUserPhone(user) == phone && _getUserPassword(user) == password,
      );
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
      
      // Não chamar initialize() novamente - já foi chamado antes
      // Apenas procurar o usuário na lista atual
      try {
        final user = _users.firstWhere((u) => u.id == userId);
        _currentUser = user;
        return true;
      } catch (e) {
        // Usuário não encontrado na lista (pode não ter carregado do servidor)
        print('⚠️ Usuário $userId não encontrado na lista');
        return false;
      }
    } catch (e) {
      print('⚠️ Erro no autoLogin: $e');
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
        'photoUrl': photoUrl, // Já vem em base64 do registro
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
        'photoUrl': photoUrl, // Já vem em base64 do registro
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

  Future<Match> createMatch(String elderlyId, String caregiverId) async {
    final match = Match(
      matchId: _generateId(),
      elderlyId: elderlyId,
      caregiverId: caregiverId,
      status: MatchStatus.pending,
      dataMatch: DateTime.now(),
    );

    // Tentar criar no backend
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/matches'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'elderlyId': elderlyId,
          'caregiverId': caregiverId,
          'status': 'pending',
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        // Usar ID do backend se disponível
        final backendMatch = Match(
          matchId: data['_id'] ?? match.matchId,
          elderlyId: elderlyId,
          caregiverId: caregiverId,
          status: MatchStatus.pending,
          dataMatch: DateTime.now(),
        );
        _matches.add(backendMatch);
        return backendMatch;
      }
    } catch (_) {
      // Se falhar, adiciona localmente
    }

    _matches.add(match);
    return match;
  }

  // Método unificado para atualizar status do match
  Future<Match?> updateMatchStatus(String matchId, MatchStatus newStatus) async {
    try {
      final match = _matches.firstWhere((m) => m.matchId == matchId);
      
      // Atualizar status localmente
      if (newStatus == MatchStatus.accepted) {
        match.accept();
      } else if (newStatus == MatchStatus.rejected) {
        match.reject();
      }

      // Atualizar no backend (não bloqueia se falhar)
      _updateMatchOnServer(matchId, newStatus).catchError((e) {
        print('Aviso: Não foi possível atualizar match no servidor: $e');
      });

      return match;
    } catch (e) {
      throw Exception('Erro ao atualizar match: $e');
    }
  }

  // Método auxiliar para atualizar no servidor
  Future<void> _updateMatchOnServer(String matchId, MatchStatus status) async {
    final statusString = status == MatchStatus.accepted ? 'accepted' : 
                        status == MatchStatus.rejected ? 'rejected' : 'pending';
    
    final response = await http.put(
      Uri.parse('$_baseUrl/matches/$matchId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': statusString}),
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode != 200) {
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

import 'match.dart';
import 'user.dart';
import 'auth_service.dart';
import '../services/data_service.dart';
import '../services/chat_service.dart';

class MatchService {
  static final MatchService _instance = MatchService._internal();
  factory MatchService() => _instance;
  MatchService._internal();

  final AuthService _authService = AuthService();
  final DataService _dataService = DataService();
  final ChatService _chatService = ChatService();

  // Obter todos os matches do usuário atual
  Future<List<Match>> getMatchesForCurrentUser() async {
    return _dataService.getMatchesForCurrentUser();
  }

  // Criar um novo match entre um idoso e um cuidador
  Future<Match> createMatch(String elderlyId, String caregiverId) async {
    return _dataService.createMatch(elderlyId, caregiverId);
  }

  // Aceitar um match
  Future<void> acceptMatch(String matchId) async {
    _dataService.acceptMatch(matchId);
    
    // Criar chat automaticamente quando match é aceito
    final matches = await _dataService.getMatchesForCurrentUser();
    final match = matches.firstWhere((m) => m.matchId == matchId);
    await _chatService.createChatFromMatch(match);
  }

  // Rejeitar um match
  Future<void> rejectMatch(String matchId) async {
    _dataService.rejectMatch(matchId);
  }

  // Obter usuário por ID (para exibir nos matches)
  Future<User?> getUserById(String userId) async {
    return _dataService.getUserById(userId);
  }
}
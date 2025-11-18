import 'match.dart';
import 'user.dart';
import '../services/data_service.dart';
import '../services/chat_service.dart';

class MatchService {
  static final MatchService _instance = MatchService._internal();
  factory MatchService() => _instance;
  MatchService._internal();

  final DataService _dataService = DataService();
  final ChatService _chatService = ChatService();
  
  // Expor dataService para acesso externo quando necessário
  DataService get dataService => _dataService;

  // Obter todos os matches do usuário atual
  Future<List<Match>> getMatchesForCurrentUser({bool reload = false}) async {
    if (reload) await _dataService.reloadMatchesFromApi();
    return _dataService.getMatchesForCurrentUser();
  }

  // Criar um novo match entre um idoso e um cuidador
  Future<Match> createMatch(String elderlyId, String caregiverId) async {
    return _dataService.createMatch(elderlyId, caregiverId);
  }

  // Aceitar um match
  Future<void> acceptMatch(String matchId) async {
    final match = await _dataService.updateMatchStatus(matchId, MatchStatus.accepted);
    if (match != null && match.status == MatchStatus.accepted) {
      await _chatService.createChatFromMatch(match);
    }
  }

  // Rejeitar um match
  Future<void> rejectMatch(String matchId) async {
    await _dataService.updateMatchStatus(matchId, MatchStatus.rejected);
  }

  // Obter usuário por ID
  User? getUserById(String userId) => _dataService.getUserById(userId);
}
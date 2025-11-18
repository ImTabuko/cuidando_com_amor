import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../models/match.dart';
import 'data_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final DataService _dataService = DataService();
  final List<Chat> _chats = [];
  final List<Message> _messages = [];
  static const String _baseUrl = 'https://cuidando-com-amor-ssud.vercel.app/api';

  DataService get dataService => _dataService;
  
  // Carregar chats do backend
  Future<void> loadChatsFromApi() async {
    final currentUser = _dataService.currentUser;
    if (currentUser == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chats?userId=${currentUser.id}'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body) as List;
        _chats.clear();
        
        for (final item in data) {
          _chats.add(Chat(
            id: (item['_id'] ?? item['id'] ?? '').toString(),
            elderlyId: (item['elderlyId'] ?? '').toString(),
            caregiverId: (item['caregiverId'] ?? '').toString(),
            createdAt: DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? DateTime.now(),
            lastMessageAt: item['lastMessageAt'] != null 
                ? DateTime.tryParse(item['lastMessageAt'].toString()) 
                : null,
            lastMessage: item['lastMessage']?.toString(),
          ));
        }
        print('✅ Chats carregados: ${_chats.length}');
      }
    } catch (e) {
      print('⚠️ Erro ao carregar chats: $e');
    }
  }
  
  // Carregar mensagens de um chat do backend
  Future<void> loadMessagesFromApi(String chatId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chats/$chatId/messages'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body) as List;
        // Remover mensagens antigas deste chat
        _messages.removeWhere((m) => m.chatId == chatId);
        
        for (final item in data) {
          _messages.add(Message(
            id: (item['_id'] ?? item['id'] ?? '').toString(),
            chatId: chatId,
            senderId: (item['senderId'] ?? '').toString(),
            receiverId: (item['receiverId'] ?? '').toString(),
            content: (item['content'] ?? '').toString(),
            type: item['type'] == 'image' ? MessageType.image : MessageType.text,
            timestamp: DateTime.tryParse(item['timestamp']?.toString() ?? '') ?? DateTime.now(),
            imageUrl: item['imageUrl']?.toString(),
            isRead: item['isRead'] == true,
          ));
        }
        print('✅ Mensagens carregadas para chat $chatId: ${_messages.where((m) => m.chatId == chatId).length}');
      }
    } catch (e) {
      print('⚠️ Erro ao carregar mensagens: $e');
    }
  }

  // Criar chat quando match é aceito
  Future<Chat> createChatFromMatch(Match match) async {
    // Verificar se já existe chat para este match
    Chat? existingChat;
    try {
      existingChat = _chats.firstWhere(
        (chat) => chat.elderlyId == match.elderlyId && chat.caregiverId == match.caregiverId,
      );
    } catch (e) {
      // Chat não existe, continuar
    }

    if (existingChat != null) {
      return existingChat;
    }

    // Tentar criar no backend PRIMEIRO
    try {
      print('📤 Criando chat no backend: Elderly=${match.elderlyId}, Caregiver=${match.caregiverId}');
      final response = await http.post(
        Uri.parse('$_baseUrl/chats'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'elderlyId': match.elderlyId,
          'caregiverId': match.caregiverId,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Chat criado no backend: ${data['_id']}');
        final backendChat = Chat(
          id: (data['_id'] ?? data['id'] ?? _generateId()).toString(),
          elderlyId: match.elderlyId,
          caregiverId: match.caregiverId,
          createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
        );
        _chats.add(backendChat);
        return backendChat;
      }
    } catch (e) {
      print('❌ Erro ao criar chat no backend: $e');
    }

    // Se falhar, criar localmente
    final chat = Chat(
      id: _generateId(),
      elderlyId: match.elderlyId,
      caregiverId: match.caregiverId,
      createdAt: DateTime.now(),
    );

    _chats.add(chat);
    return chat;
  }

  // Obter chats do usuário atual
  Future<List<ChatWithUsers>> getChatsForCurrentUser({bool reload = false}) async {
    final currentUser = _dataService.currentUser;
    if (currentUser == null) return [];

    // Carregar do backend se necessário
    if (reload || _chats.isEmpty) {
      await loadChatsFromApi();
    }

    final userChats = _chats.where((chat) => 
      chat.elderlyId == currentUser.id || chat.caregiverId == currentUser.id
    ).toList();

    final List<ChatWithUsers> chatsWithUsers = [];

    for (final chat in userChats) {
      final elderly = _dataService.getUserById(chat.elderlyId);
      final caregiver = _dataService.getUserById(chat.caregiverId);

      if (elderly != null && caregiver != null) {
        // Calcular unreadCount para este chat específico
        final unreadCount = _messages
            .where((message) => 
              message.chatId == chat.id && 
              message.receiverId == currentUser.id && 
              !message.isRead
            )
            .length;
        
        final updatedChat = chat.copyWith(unreadCount: unreadCount);
        
        chatsWithUsers.add(ChatWithUsers(
          chat: updatedChat,
          elderly: elderly,
          caregiver: caregiver,
        ));
      }
    }

    return chatsWithUsers;
  }

  // Obter mensagens de um chat
  Future<List<Message>> getMessagesForChat(String chatId, {bool reload = false}) async {
    // Carregar do backend se necessário
    if (reload || _messages.where((m) => m.chatId == chatId).isEmpty) {
      await loadMessagesFromApi(chatId);
    }
    
    final messages = _messages
        .where((message) => message.chatId == chatId)
        .toList();
    
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  // Enviar mensagem
  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
  }) async {
    // Tentar salvar no backend PRIMEIRO
    try {
      print('📤 Enviando mensagem no backend: Chat=$chatId');
      final response = await http.post(
        Uri.parse('$_baseUrl/chats/$chatId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'senderId': senderId,
          'receiverId': receiverId,
          'content': content,
          'type': type == MessageType.image ? 'image' : 'text',
          'imageUrl': imageUrl,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Mensagem enviada no backend: ${data['_id']}');
        final backendMessage = Message(
          id: (data['_id'] ?? data['id'] ?? _generateId()).toString(),
          chatId: chatId,
          senderId: senderId,
          receiverId: receiverId,
          content: content,
          type: type,
          timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ?? DateTime.now(),
          imageUrl: imageUrl,
          isRead: false,
        );
        _messages.add(backendMessage);
        
        // Atualizar chat com última mensagem
        final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
        if (chatIndex != -1) {
          _chats[chatIndex] = _chats[chatIndex].copyWith(
            lastMessageAt: backendMessage.timestamp,
            lastMessage: content,
          );
        }
        
        return backendMessage;
      }
    } catch (e) {
      print('❌ Erro ao enviar mensagem no backend: $e');
    }

    // Se falhar, criar localmente
    final message = Message(
      id: _generateId(),
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
    );

    _messages.add(message);

    // Atualizar chat com última mensagem
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      _chats[chatIndex] = _chats[chatIndex].copyWith(
        lastMessageAt: message.timestamp,
        lastMessage: content,
      );
    }

    return message;
  }

  // Marcar mensagens como lidas
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    // Atualizar no backend
    try {
      await http.put(
        Uri.parse('$_baseUrl/chats/$chatId/messages/read'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      print('⚠️ Erro ao marcar mensagens como lidas no backend: $e');
    }
    
    // Atualizar localmente
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].chatId == chatId && 
          _messages[i].receiverId == userId && 
          !_messages[i].isRead) {
        _messages[i] = _messages[i].copyWith(isRead: true);
      }
    }
  }

  // Obter contagem de mensagens não lidas
  int getUnreadCount(String userId) {
    return _messages
        .where((message) => message.receiverId == userId && !message.isRead)
        .length;
  }

  // Obter chat por ID
  Future<Chat?> getChatById(String chatId) async {
    try {
      return _chats.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      return null;
    }
  }

  // Verificar se existe chat entre dois usuários
  Future<Chat?> getChatBetweenUsers(String userId1, String userId2) async {
    try {
      return _chats.firstWhere((chat) => 
        (chat.elderlyId == userId1 && chat.caregiverId == userId2) ||
        (chat.elderlyId == userId2 && chat.caregiverId == userId1)
      );
    } catch (e) {
      return null;
    }
  }

  // Obter usuário do chat (o outro participante)
  Future<User?> getChatPartner(String chatId, String currentUserId) async {
    final chat = await getChatById(chatId);
    if (chat == null) return null;

    final partnerId = chat.elderlyId == currentUserId 
        ? chat.caregiverId 
        : chat.elderlyId;

    return _dataService.getUserById(partnerId);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }
}

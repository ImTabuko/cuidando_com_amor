import 'dart:math';
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

  DataService get dataService => _dataService;

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
  Future<List<ChatWithUsers>> getChatsForCurrentUser() async {
    final currentUser = _dataService.currentUser;
    if (currentUser == null) return [];

    final userChats = _chats.where((chat) => 
      chat.elderlyId == currentUser.id || chat.caregiverId == currentUser.id
    ).toList();

    final List<ChatWithUsers> chatsWithUsers = [];

    for (final chat in userChats) {
      final elderly = await _dataService.getUserById(chat.elderlyId);
      final caregiver = await _dataService.getUserById(chat.caregiverId);

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
  Future<List<Message>> getMessagesForChat(String chatId) async {
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

    return await _dataService.getUserById(partnerId);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }
}

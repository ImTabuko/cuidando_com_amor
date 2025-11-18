import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../services/accessibility_service.dart';
import '../services/photo_service.dart';
import '../widgets/accessible_text.dart';
import '../utils/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  final User partner;

  const ChatScreen({
    super.key,
    required this.chat,
    required this.partner,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final AccessibilityService _accessibilityService = AccessibilityService();
  final PhotoService _photoService = PhotoService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isLargeTextEnabled = false;

  @override
  void initState() {
    super.initState();
    _isLargeTextEnabled = _accessibilityService.isLargeTextEnabled;
    _accessibilityService.addListener(_updateState);
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _accessibilityService.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    setState(() {
      _isLargeTextEnabled = _accessibilityService.isLargeTextEnabled;
    });
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _messages = await _chatService.getMessagesForChat(widget.chat.id);
      
      // Marcar mensagens como lidas
      final currentUser = _chatService.dataService.currentUser;
      if (currentUser != null) {
        await _chatService.markMessagesAsRead(widget.chat.id, currentUser.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar mensagens: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = _chatService.dataService.currentUser;
    if (currentUser == null) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      await _chatService.sendMessage(
        chatId: widget.chat.id,
        senderId: currentUser.id,
        receiverId: widget.partner.id,
        content: content,
      );

      _loadMessages();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar mensagem: ${e.toString()}')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Desabilita botão de voltar do Android
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
          children: [
            _photoService.buildProfilePhoto(
              photoUrl: widget.partner.photoUrl,
              radius: _accessibilityService.isLargeTextEnabled ? 20 : 16,
              showEditIcon: false,
            ),
            SizedBox(width: _accessibilityService.smallSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TitleText(
                    widget.partner.fullName,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  BodyText(
                    widget.partner.city,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: _accessibilityService.defaultSpacing),
                        BodyText('Carregando mensagens...'),
                      ],
                    ),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: _accessibilityService.isLargeTextEnabled ? 80 : 60,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: _accessibilityService.defaultSpacing),
                            BodyText(
                              'Nenhuma mensagem ainda',
                              color: Colors.grey[600],
                            ),
                            SizedBox(height: _accessibilityService.smallSpacing),
                            BodyText(
                              'Envie uma mensagem para começar a conversa',
                              color: Colors.grey[500],
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(_accessibilityService.defaultSpacing),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final currentUser = _chatService.dataService.currentUser;
    final isMe = currentUser?.id == message.senderId;

    return Container(
      margin: EdgeInsets.only(
        bottom: _accessibilityService.smallSpacing,
        left: isMe ? _accessibilityService.largeSpacing * 2 : 0,
        right: isMe ? 0 : _accessibilityService.largeSpacing * 2,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _photoService.buildProfilePhoto(
              photoUrl: widget.partner.photoUrl,
              radius: _accessibilityService.isLargeTextEnabled ? 16 : 12,
              showEditIcon: false,
            ),
            SizedBox(width: _accessibilityService.smallSpacing),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _accessibilityService.defaultSpacing,
                vertical: _accessibilityService.smallSpacing,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BodyText(
                    message.content,
                    color: isMe ? Colors.white : Colors.black87,
                  ),
                  SizedBox(height: _accessibilityService.smallSpacing / 2),
                  HintText(
                    _formatTime(message.timestamp),
                    color: isMe ? Colors.white70 : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            SizedBox(width: _accessibilityService.smallSpacing),
            _photoService.buildProfilePhoto(
              photoUrl: currentUser?.photoUrl,
              radius: _accessibilityService.isLargeTextEnabled ? 16 : 12,
              showEditIcon: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(_accessibilityService.defaultSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Digite sua mensagem...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: _accessibilityService.defaultSpacing,
                  vertical: _accessibilityService.smallSpacing,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: _accessibilityService.smallSpacing),
          FloatingActionButton(
            onPressed: _sendMessage,
            backgroundColor: AppColors.primary,
            mini: true,
            child: Icon(
              Icons.send,
              color: Colors.white,
              size: _accessibilityService.iconSize,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

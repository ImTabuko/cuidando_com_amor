import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../services/accessibility_service.dart';
import '../services/photo_service.dart';
import '../widgets/accessible_text.dart';
import 'chat_screen.dart';
import '../utils/app_colors.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final ChatService _chatService = ChatService();
  final AccessibilityService _accessibilityService = AccessibilityService();
  final PhotoService _photoService = PhotoService();
  List<ChatWithUsers> _chats = [];
  bool _isLoading = true;
  bool _isLargeTextEnabled = false;

  @override
  void initState() {
    super.initState();
    _isLargeTextEnabled = _accessibilityService.isLargeTextEnabled;
    _accessibilityService.addListener(_updateState);
    _loadChats();
  }

  @override
  void dispose() {
    _accessibilityService.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    setState(() {
      _isLargeTextEnabled = _accessibilityService.isLargeTextEnabled;
    });
  }

  Future<void> _loadChats({bool reload = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sempre recarregar do backend para garantir dados atualizados
      _chats = await _chatService.getChatsForCurrentUser(reload: true);
    } catch (e) {
      print('❌ Erro ao carregar chats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar chats: ${e.toString()}')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
        title: TitleText('Conversas', color: Colors.white),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: _accessibilityService.iconSize),
            onPressed: _loadChats,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: _accessibilityService.defaultSpacing),
                  BodyText('Carregando conversas...'),
                ],
              ),
            )
          : _chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: _accessibilityService.isLargeTextEnabled ? 100 : 80,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: _accessibilityService.defaultSpacing),
                      TitleText(
                        'Nenhuma conversa ainda',
                        color: Colors.grey[600],
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: _accessibilityService.smallSpacing),
                      BodyText(
                        'Quando você aceitar um match, poderá conversar aqui',
                        color: Colors.grey[500],
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  child: ListView.builder(
                    padding: EdgeInsets.all(_accessibilityService.defaultSpacing),
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      return _buildChatCard(_chats[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildChatCard(ChatWithUsers chatWithUsers) {
    final chat = chatWithUsers.chat;
    final currentUser = _chatService.dataService.currentUser;
    final isElderly = currentUser is ElderlyUser;
    final partner = isElderly ? chatWithUsers.caregiver : chatWithUsers.elderly;

    return Card(
      margin: EdgeInsets.only(bottom: _accessibilityService.defaultSpacing),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(_accessibilityService.defaultSpacing),
        leading: _photoService.buildProfilePhoto(
          photoUrl: partner.photoUrl,
          radius: _accessibilityService.isLargeTextEnabled ? 30 : 25,
          showEditIcon: false,
        ),
        title: TitleText(
          partner.fullName,
          fontWeight: FontWeight.bold,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: _accessibilityService.smallSpacing / 2),
            BodyText(
              chat.lastMessage ?? 'Nova conversa',
              color: Colors.grey[600],
              maxLines: 1,
            ),
            if (chat.lastMessageAt != null) ...[
              SizedBox(height: _accessibilityService.smallSpacing / 2),
              HintText(
                _formatDateTime(chat.lastMessageAt!),
                color: Colors.grey[500],
              ),
            ],
          ],
        ),
        trailing: chat.unreadCount > 0
            ? Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _accessibilityService.smallSpacing,
                  vertical: _accessibilityService.smallSpacing / 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: BodyText(
                  '${chat.unreadCount}',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chat: chat,
                partner: partner,
              ),
            ),
          );
          _loadChats(); // Recarregar para atualizar contadores
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

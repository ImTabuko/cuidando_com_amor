import 'user.dart';

class Chat {
  final String id;
  final String elderlyId;
  final String caregiverId;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final int unreadCount;

  Chat({
    required this.id,
    required this.elderlyId,
    required this.caregiverId,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  Chat copyWith({
    String? id,
    String? elderlyId,
    String? caregiverId,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? lastMessage,
    int? unreadCount,
  }) {
    return Chat(
      id: id ?? this.id,
      elderlyId: elderlyId ?? this.elderlyId,
      caregiverId: caregiverId ?? this.caregiverId,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'elderlyId': elderlyId,
      'caregiverId': caregiverId,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
    };
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      elderlyId: json['elderlyId'],
      caregiverId: json['caregiverId'],
      createdAt: DateTime.parse(json['createdAt']),
      lastMessageAt: json['lastMessageAt'] != null 
          ? DateTime.parse(json['lastMessageAt']) 
          : null,
      lastMessage: json['lastMessage'],
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

class ChatWithUsers {
  final Chat chat;
  final User elderly;
  final User caregiver;

  ChatWithUsers({
    required this.chat,
    required this.elderly,
    required this.caregiver,
  });
}


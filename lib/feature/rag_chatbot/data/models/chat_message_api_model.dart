import '../../domain/entities/chat_message_entity.dart';

class ChatMessageApiModel {
  final String id;
  final String threadId;
  final String role;
  final String content;
  final DateTime? createdAt;

  ChatMessageApiModel({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    this.createdAt,
  });

  factory ChatMessageApiModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageApiModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      threadId: (json['threadId'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  ChatMessageEntity toEntity() => ChatMessageEntity(
        id: id,
        threadId: threadId,
        role: role,
        content: content,
        createdAt: createdAt,
        pending: false,
        failed: false,
      );
}

import 'package:motion_ai/feature/rag_chatbot/data/models/chat_message_api_model.dart';
import '../../domain/entities/chat_thread_entity.dart';

class ChatThreadApiModel {
  final String id;
  final String workspaceId;
  final String userId;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ChatMessageApiModel> messages;

  ChatThreadApiModel({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.title,
    this.createdAt,
    this.updatedAt,
    required this.messages,
  });

  factory ChatThreadApiModel.fromJson(Map<String, dynamic> json) {
    final rawMsgs = (json['messages'] as List?) ?? [];

    return ChatThreadApiModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      workspaceId: (json['workspaceId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      title: (json['title'] ?? 'New chat').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      messages: rawMsgs
          .whereType<Map>()
          .map((m) => ChatMessageApiModel.fromJson(m.cast<String, dynamic>()))
          .toList(),
    );
  }

  ChatThreadEntity toEntity() => ChatThreadEntity(
        id: id,
        workspaceId: workspaceId,
        userId: userId,
        title: title,
        createdAt: createdAt,
        updatedAt: updatedAt,
        messages: messages.map((m) => m.toEntity()).toList(),
      );
}

import 'chat_message_entity.dart';

class ChatThreadEntity {
  final String id;
  final String workspaceId;
  final String userId;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ChatMessageEntity> messages;

  const ChatThreadEntity({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.title,
    this.createdAt,
    this.updatedAt,
    required this.messages,
  });

  ChatThreadEntity copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatMessageEntity>? messages,
  }) {
    return ChatThreadEntity(
      id: id,
      workspaceId: workspaceId,
      userId: userId,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}

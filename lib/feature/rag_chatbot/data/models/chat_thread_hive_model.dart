import 'package:hive/hive.dart';
import 'package:motion_ai/core/constants/hive_table_constant.dart';
import '../../domain/entities/chat_thread_entity.dart';
import 'chat_message_hive_model.dart';

part 'chat_thread_hive_model.g.dart';

@HiveType(typeId: HiveTableConstant.chatThreadTypeId)
class ChatThreadHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String workspaceId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final DateTime? createdAt;

  @HiveField(5)
  final DateTime? updatedAt;

  @HiveField(6)
  final List<ChatMessageHiveModel> messages;

  ChatThreadHiveModel({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.title,
    this.createdAt,
    this.updatedAt,
    required this.messages,
  });

  ChatThreadEntity toEntity() => ChatThreadEntity(
        id: id,
        workspaceId: workspaceId,
        userId: userId,
        title: title,
        createdAt: createdAt,
        updatedAt: updatedAt,
        messages: messages.map((m) => m.toEntity()).toList(),
      );

  factory ChatThreadHiveModel.fromEntity(ChatThreadEntity e) {
    return ChatThreadHiveModel(
      id: e.id,
      workspaceId: e.workspaceId,
      userId: e.userId,
      title: e.title,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      messages: e.messages.map(ChatMessageHiveModel.fromEntity).toList(),
    );
  }

  ChatThreadHiveModel copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatMessageHiveModel>? messages,
  }) {
    return ChatThreadHiveModel(
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

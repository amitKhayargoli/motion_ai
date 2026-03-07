import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:motion_ai/core/constants/hive_table_constant.dart';
import '../../domain/entities/chat_message_entity.dart';

part 'chat_message_hive_model.g.dart';

@HiveType(typeId: HiveTableConstant.chatMessageTypeId)
class ChatMessageHiveModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String threadId;

  @HiveField(2)
  final String role;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final DateTime? createdAt;

  @HiveField(5)
  final bool pending;

  @HiveField(6)
  final bool failed;

  /// JSON-encoded list of {id, title} — only set for note-list responses
  @HiveField(7)
  final String? notesJson;

  @HiveField(8)
  final String? kind;

  ChatMessageHiveModel({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    this.createdAt,
    this.pending = false,
    this.failed = false,
    this.notesJson,
    this.kind,
  });

  ChatMessageEntity toEntity() {
    List<ChatNoteRef>? notes;
    if (notesJson != null && notesJson!.isNotEmpty) {
      try {
        final list = jsonDecode(notesJson!) as List;
        notes = list
            .map((n) => ChatNoteRef(
                  id: (n["id"] ?? "").toString(),
                  title: (n["title"] ?? "Untitled").toString(),
                ))
            .toList();
      } catch (_) {}
    }
    return ChatMessageEntity(
      id: id,
      threadId: threadId,
      role: role,
      content: content,
      createdAt: createdAt,
      pending: pending,
      failed: failed,
      kind: kind,
      notes: notes,
    );
  }

  factory ChatMessageHiveModel.fromEntity(ChatMessageEntity e) {
    String? notesJson;
    if (e.notes != null && e.notes!.isNotEmpty) {
      notesJson = jsonEncode(
        e.notes!.map((n) => {"id": n.id, "title": n.title}).toList(),
      );
    }
    return ChatMessageHiveModel(
      id: e.id,
      threadId: e.threadId,
      role: e.role,
      content: e.content,
      createdAt: e.createdAt,
      pending: e.pending,
      failed: e.failed,
      notesJson: notesJson,
      kind: e.kind,
    );
  }

  ChatMessageHiveModel copyWith({
    String? content,
    DateTime? createdAt,
    bool? pending,
    bool? failed,
    String? notesJson,
    String? kind,
  }) {
    return ChatMessageHiveModel(
      id: id,
      threadId: threadId,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      pending: pending ?? this.pending,
      failed: failed ?? this.failed,
      notesJson: notesJson ?? this.notesJson,
      kind: kind ?? this.kind,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "threadId": threadId,
      "role": role,
      "content": content,
      "createdAt": createdAt?.toIso8601String(),
      "pending": pending,
      "failed": failed,
      "notesJson": notesJson,
      "kind": kind,
    };
  }

  factory ChatMessageHiveModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageHiveModel(
      id: (json["id"] ?? "").toString(),
      threadId: (json["threadId"] ?? "").toString(),
      role: (json["role"] ?? "").toString(),
      content: (json["content"] ?? "").toString(),
      createdAt: json["createdAt"] != null
          ? DateTime.tryParse(json["createdAt"].toString())
          : null,
      pending: json["pending"] == true,
      failed: json["failed"] == true,
      notesJson: json["notesJson"] as String?,
      kind: json["kind"] as String?,
    );
  }
}

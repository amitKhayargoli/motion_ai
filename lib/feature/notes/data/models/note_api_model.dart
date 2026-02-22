import '../../domain/entities/note_entity.dart';

class NoteApiModel {
  final String id;
  final String workspaceId;
  final String title;
  final String content;
  final String? summary;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NoteApiModel({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.content,
    this.summary,
    this.createdAt,
    this.updatedAt,
  });

  factory NoteApiModel.fromJson(Map<String, dynamic> json) {
    return NoteApiModel(
      id: (json['_id'] ?? json['id']).toString(),
      workspaceId: (json['workspaceId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      summary: json['summary']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  NoteEntity toEntity() => NoteEntity(
    id: id,
    workspaceId: workspaceId,
    title: title,
    content: content,
    summary: summary,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

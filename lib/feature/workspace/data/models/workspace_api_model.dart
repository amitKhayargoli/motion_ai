import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';

class WorkspaceApiModel {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? updatedAt;

  WorkspaceApiModel({
    required this.id,
    required this.name,
    required this.createdAt,
    this.updatedAt,
  });

  factory WorkspaceApiModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceApiModel(
      id: (json['id'] ?? json['_id']).toString(),
      name: (json['name'] ?? '').toString(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }

  WorkspaceEntity toEntity() =>
      WorkspaceEntity(id: id, name: name, createdAt: createdAt);

  static WorkspaceApiModel fromEntity(WorkspaceEntity e) =>
      WorkspaceApiModel(id: e.id, name: e.name, createdAt: e.createdAt);
}

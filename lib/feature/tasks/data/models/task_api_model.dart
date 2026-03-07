import '../../domain/entities/task_entity.dart';

class TaskApiModel {
  final String id;
  final String workspaceId;
  final String title;
  final String? description;
  final bool isCompleted;
  final String? priority;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TaskApiModel({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  factory TaskApiModel.fromJson(Map<String, dynamic> json) {
    return TaskApiModel(
      id: (json['_id'] ?? json['id']).toString(),
      workspaceId: (json['workspaceId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      isCompleted: json['isCompleted'] == true,
      priority: json['priority']?.toString(),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  TaskEntity toEntity() => TaskEntity(
        id: id,
        workspaceId: workspaceId,
        title: title,
        description: description,
        isCompleted: isCompleted,
        priority: priority,
        dueDate: dueDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

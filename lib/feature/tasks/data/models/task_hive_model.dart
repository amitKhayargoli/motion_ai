import 'package:hive/hive.dart';
import 'package:motion_ai/core/constants/hive_table_constant.dart';
import 'package:motion_ai/feature/tasks/domain/entities/task_entity.dart';

part 'task_hive_model.g.dart';

/// syncStatus:
/// 0 = synced
/// 1 = pendingCreate
/// 2 = pendingUpdate
/// 3 = pendingDelete
@HiveType(typeId: HiveTableConstant.taskTypeId)
class TaskHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String workspaceId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final bool isCompleted;

  @HiveField(5)
  final String? priority;

  @HiveField(6)
  final DateTime? dueDate;

  @HiveField(7)
  final DateTime? createdAt;

  @HiveField(8)
  final DateTime? updatedAt;

  @HiveField(9)
  final int syncStatus;

  @HiveField(10)
  final String? serverId;

  TaskHiveModel({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
    this.serverId,
  });

  TaskEntity toEntity() => TaskEntity(
        id: serverId ?? id,
        workspaceId: workspaceId,
        title: title,
        description: description,
        isCompleted: isCompleted,
        priority: priority,
        dueDate: dueDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory TaskHiveModel.fromEntity(
    TaskEntity e, {
    int syncStatus = 0,
    String? serverId,
    String? localId,
  }) {
    return TaskHiveModel(
      id: localId ?? e.id,
      workspaceId: e.workspaceId,
      title: e.title,
      description: e.description,
      isCompleted: e.isCompleted,
      priority: e.priority,
      dueDate: e.dueDate,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      syncStatus: syncStatus,
      serverId: serverId,
    );
  }

  TaskHiveModel copyWith({
    String? id,
    String? workspaceId,
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
    String? serverId,
  }) {
    return TaskHiveModel(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      serverId: serverId ?? this.serverId,
    );
  }
}

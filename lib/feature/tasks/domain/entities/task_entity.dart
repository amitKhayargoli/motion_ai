enum TaskSyncStatus {
  synced,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
}

enum TaskPriority {
  low,
  medium,
  high,
}

class TaskEntity {
  final String id;
  final String workspaceId;
  final String title;
  final String? description;
  final bool isCompleted;
  final String? priority; // LOW | MEDIUM | HIGH
  final DateTime? dueDate;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final TaskSyncStatus syncStatus;

  const TaskEntity({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = TaskSyncStatus.synced,
  });

  TaskEntity copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    TaskSyncStatus? syncStatus,
  }) {
    return TaskEntity(
      id: id,
      workspaceId: workspaceId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

import 'package:motion_ai/feature/tasks/domain/entities/task_entity.dart';

enum TasksStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  error,
}

class TasksState {
  final TasksStatus status;
  final String? error;
  final String? workspaceId;
  final List<TaskEntity> tasks;

  const TasksState({
    required this.status,
    required this.tasks,
    required this.workspaceId,
    required this.error,
  });

  factory TasksState.initial() => const TasksState(
        status: TasksStatus.initial,
        tasks: [],
        workspaceId: null,
        error: null,
      );

  TasksState copyWith({
    TasksStatus? status,
    String? workspaceId,
    List<TaskEntity>? tasks,
    String? error,
    bool clearError = false,
  }) {
    return TasksState(
      status: status ?? this.status,
      workspaceId: workspaceId ?? this.workspaceId,
      tasks: tasks ?? this.tasks,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

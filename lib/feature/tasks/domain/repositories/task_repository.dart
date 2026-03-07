import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import '../entities/task_entity.dart';

abstract class ITaskRepository {
  Future<Either<Failure, List<TaskEntity>>> getWorkspaceTasks(
    String workspaceId, {
    bool forceRefresh = false,
  });

  Future<Either<Failure, TaskEntity>> createTask(
    String workspaceId,
    String title, {
    String? description,
    String? priority,
    DateTime? dueDate,
  });

  Future<Either<Failure, TaskEntity>> updateTask(
    String taskId, {
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    DateTime? dueDate,
  });

  Future<Either<Failure, bool>> deleteTask(String taskId);
}

import '../models/task_api_model.dart';
import '../models/task_hive_model.dart';

abstract class ITaskLocalDataSource {
  Future<void> upsertTasks(List<TaskHiveModel> tasks);
  Future<void> upsertTask(TaskHiveModel task);
  Future<List<TaskHiveModel>> getWorkspaceTasks(String workspaceId);
  Future<TaskHiveModel?> getTaskById(String taskId);
  Future<List<TaskHiveModel>> getPendingWorkspaceTasks(String workspaceId);
  Future<void> deleteTask(String taskId);
  Future<void> clearWorkspaceTasks(String workspaceId);
}

abstract class ITaskRemoteDataSource {
  Future<List<TaskApiModel>> getWorkspaceTasks(String workspaceId);
  Future<TaskApiModel> createTask({
    required String workspaceId,
    required String title,
    String? description,
    String? priority,
    DateTime? dueDate,
  });
  Future<TaskApiModel> updateTask({
    required String taskId,
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    DateTime? dueDate,
  });
  Future<void> deleteTask(String taskId);
}

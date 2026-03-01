import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/core/services/hive/hive_service.dart';
import 'package:motion_ai/feature/tasks/data/datasources/task_datasource.dart';
import 'package:motion_ai/feature/tasks/data/models/task_hive_model.dart';

final taskLocalDatasourceProvider = Provider<ITaskLocalDataSource>((ref) {
  return TaskLocalDatasource(hive: ref.read(hiveServiceProvider));
});

class TaskLocalDatasource implements ITaskLocalDataSource {
  final HiveService hive;
  TaskLocalDatasource({required this.hive});

  @override
  Future<void> upsertTasks(List<TaskHiveModel> tasks) =>
      hive.upsertTasks(tasks);

  @override
  Future<void> upsertTask(TaskHiveModel task) => hive.upsertTask(task);

  @override
  Future<List<TaskHiveModel>> getWorkspaceTasks(String workspaceId) =>
      hive.getWorkspaceTasks(workspaceId);

  @override
  Future<TaskHiveModel?> getTaskById(String taskId) => hive.getTaskById(taskId);

  @override
  Future<void> deleteTask(String taskId) => hive.deleteTask(taskId);

  @override
  Future<void> clearWorkspaceTasks(String workspaceId) =>
      hive.clearWorkspaceTasks(workspaceId);

  @override
  Future<List<TaskHiveModel>> getPendingWorkspaceTasks(String workspaceId) =>
      hive.getPendingTasksForWorkspace(workspaceId);
}

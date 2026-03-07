import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/api/api_client.dart';
import 'package:motion_ai/core/api/api_endpoints.dart';
import 'package:motion_ai/core/providers/providers.dart';

import '../task_datasource.dart';
import '../../models/task_api_model.dart';

final taskRemoteDatasourceProvider = Provider<ITaskRemoteDataSource>((ref) {
  return TaskRemoteDatasource(api: ref.read(apiClientProvider));
});

class TaskRemoteDatasource implements ITaskRemoteDataSource {
  final ApiClient _api;

  TaskRemoteDatasource({required ApiClient api}) : _api = api;

  dynamic _extractData(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body['data'];
    }
    throw Exception("Invalid API response format");
  }

  @override
  Future<TaskApiModel> createTask({
    required String workspaceId,
    required String title,
    String? description,
    String? priority,
    DateTime? dueDate,
  }) async {
    final data = <String, dynamic>{
      "workspaceId": workspaceId,
      "title": title,
    };
    if (description != null) data["description"] = description;
    if (priority != null) data["priority"] = priority;
    if (dueDate != null) data["dueDate"] = dueDate.toIso8601String();

    final res = await _api.post(ApiEndpoints.createTask, data: data);
    final extracted = _extractData(res.data);
    return TaskApiModel.fromJson(extracted as Map<String, dynamic>);
  }

  @override
  Future<List<TaskApiModel>> getWorkspaceTasks(String workspaceId) async {
    final res = await _api.get(ApiEndpoints.workspaceTasks(workspaceId));
    final data = _extractData(res.data);

    if (data is List) {
      return data
          .map((e) => TaskApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  @override
  Future<TaskApiModel> updateTask({
    required String taskId,
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    DateTime? dueDate,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data["title"] = title;
    if (description != null) data["description"] = description;
    if (isCompleted != null) data["isCompleted"] = isCompleted;
    if (priority != null) data["priority"] = priority;
    if (dueDate != null) data["dueDate"] = dueDate.toIso8601String();

    final res = await _api.put(ApiEndpoints.taskById(taskId), data: data);
    final extracted = _extractData(res.data);
    return TaskApiModel.fromJson(extracted as Map<String, dynamic>);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _api.delete(ApiEndpoints.taskById(taskId));
  }
}

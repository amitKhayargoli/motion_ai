import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/feature/tasks/data/providers/task_repository_provider.dart';
import 'package:motion_ai/feature/tasks/domain/usecases/create_task_usecase.dart';
import 'package:motion_ai/feature/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:motion_ai/feature/tasks/domain/usecases/get_workspace_tasks_usecase.dart';
import 'package:motion_ai/feature/tasks/domain/usecases/update_task_usecase.dart';

final getWorkspaceTasksUseCaseProvider =
    Provider<GetWorkspaceTasksUseCase>((ref) {
  return GetWorkspaceTasksUseCase(ref.read(taskRepositoryProvider));
});

final createTaskUseCaseProvider = Provider<CreateTaskUseCase>((ref) {
  return CreateTaskUseCase(ref.read(taskRepositoryProvider));
});

final updateTaskUseCaseProvider = Provider<UpdateTaskUseCase>((ref) {
  return UpdateTaskUseCase(ref.read(taskRepositoryProvider));
});

final deleteTaskUseCaseProvider = Provider<DeleteTaskUseCase>((ref) {
  return DeleteTaskUseCase(ref.read(taskRepositoryProvider));
});

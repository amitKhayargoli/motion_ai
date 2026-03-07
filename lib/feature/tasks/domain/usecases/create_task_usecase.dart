import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/tasks/domain/entities/task_entity.dart';
import 'package:motion_ai/feature/tasks/domain/repositories/task_repository.dart';

class CreateTaskParams {
  final String workspaceId;
  final String title;
  final String? description;
  final String? priority;
  final DateTime? dueDate;

  const CreateTaskParams({
    required this.workspaceId,
    required this.title,
    this.description,
    this.priority,
    this.dueDate,
  });
}

class CreateTaskUseCase
    implements UseCaseWithParams<TaskEntity, CreateTaskParams> {
  final ITaskRepository repository;
  CreateTaskUseCase(this.repository);

  @override
  Future<Either<Failure, TaskEntity>> call(CreateTaskParams params) {
    return repository.createTask(
      params.workspaceId,
      params.title,
      description: params.description,
      priority: params.priority,
      dueDate: params.dueDate,
    );
  }
}

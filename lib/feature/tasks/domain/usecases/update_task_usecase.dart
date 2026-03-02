import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/tasks/domain/entities/task_entity.dart';
import 'package:motion_ai/feature/tasks/domain/repositories/task_repository.dart';

class UpdateTaskParams {
  final String taskId;
  final String? title;
  final String? description;
  final bool? isCompleted;
  final String? priority;
  final DateTime? dueDate;

  const UpdateTaskParams({
    required this.taskId,
    this.title,
    this.description,
    this.isCompleted,
    this.priority,
    this.dueDate,
  });
}

class UpdateTaskUseCase
    implements UseCaseWithParams<TaskEntity, UpdateTaskParams> {
  final ITaskRepository repository;
  UpdateTaskUseCase(this.repository);

  @override
  Future<Either<Failure, TaskEntity>> call(UpdateTaskParams params) {
    return repository.updateTask(
      params.taskId,
      title: params.title,
      description: params.description,
      isCompleted: params.isCompleted,
      priority: params.priority,
      dueDate: params.dueDate,
    );
  }
}

import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/tasks/domain/repositories/task_repository.dart';

class DeleteTaskParams {
  final String taskId;
  const DeleteTaskParams(this.taskId);
}

class DeleteTaskUseCase implements UseCaseWithParams<bool, DeleteTaskParams> {
  final ITaskRepository repository;
  DeleteTaskUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(DeleteTaskParams params) {
    return repository.deleteTask(params.taskId);
  }
}

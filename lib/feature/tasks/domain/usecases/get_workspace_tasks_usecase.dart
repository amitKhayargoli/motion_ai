import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/tasks/domain/entities/task_entity.dart';
import 'package:motion_ai/feature/tasks/domain/repositories/task_repository.dart';

class GetWorkspaceTasksParams {
  final String workspaceId;
  final bool forceRefresh;
  const GetWorkspaceTasksParams(this.workspaceId, {this.forceRefresh = false});
}

class GetWorkspaceTasksUseCase
    implements UseCaseWithParams<List<TaskEntity>, GetWorkspaceTasksParams> {
  final ITaskRepository repository;

  GetWorkspaceTasksUseCase(this.repository);

  @override
  Future<Either<Failure, List<TaskEntity>>> call(
    GetWorkspaceTasksParams params,
  ) {
    return repository.getWorkspaceTasks(
      params.workspaceId,
      forceRefresh: params.forceRefresh,
    );
  }
}

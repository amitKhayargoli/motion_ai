import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/workspace/data/repositories/workspace_repository.dart';
import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';
import 'package:motion_ai/feature/workspace/domain/repositories/workspace_repository.dart';

final updateWorkspaceUsecaseProvider = Provider<UpdateWorkspaceUsecase>(
  (ref) => UpdateWorkspaceUsecase(ref.read(workspaceRepositoryProvider)),
);

class UpdateWorkspaceParams {
  final String workspaceId;
  final String name;

  const UpdateWorkspaceParams({
    required this.workspaceId,
    required this.name,
  });
}

class UpdateWorkspaceUsecase
    implements UseCaseWithParams<WorkspaceEntity, UpdateWorkspaceParams> {
  final IWorkspaceRepository _repository;
  UpdateWorkspaceUsecase(this._repository);

  @override
  Future<Either<Failure, WorkspaceEntity>> call(UpdateWorkspaceParams params) {
    return _repository.updateWorkspace(params.workspaceId, params.name);
  }
}

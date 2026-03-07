import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';

abstract class IWorkspaceRepository {
  Future<Either<Failure, WorkspaceEntity>> createWorkspace(String name);

  Future<Either<Failure, WorkspaceEntity>> joinByInviteLink(String inviteLink);

  Future<Either<Failure, List<WorkspaceEntity>>> getMyWorkspaces();

  Future<Either<Failure, WorkspaceEntity>> updateWorkspace(
      String workspaceId, String name);

  Future<Either<Failure, bool>> deleteWorkspace(String workspaceId);
}

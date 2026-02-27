import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/workspace/data/repositories/workspace_repository.dart';
import 'package:motion_ai/feature/workspace/domain/repositories/workspace_repository.dart';

final getWorkspacesUsecaseProvider = Provider<GetWorkspacesUsecase>(
  (ref) => GetWorkspacesUsecase(ref.read(workspaceRepositoryProvider)),
);

class GetWorkspacesUsecase implements UseCaseWithoutParams {
  final IWorkspaceRepository _repository;
  GetWorkspacesUsecase(this._repository);

  @override
  Future<Either<Failure, dynamic>> call() {
    return _repository.getMyWorkspaces();
  }
}
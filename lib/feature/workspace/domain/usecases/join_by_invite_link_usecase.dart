import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/workspace/data/repositories/workspace_repository.dart';
import 'package:motion_ai/feature/workspace/domain/repositories/workspace_repository.dart';

final joinByInviteLinkUsecaseProvider = Provider<JoinByInviteLinkUsecase>(
  (ref) => JoinByInviteLinkUsecase(ref.read(workspaceRepositoryProvider)),
);

class JoinByInviteLinkUsecase implements UseCaseWithParams<dynamic, String> {
  final IWorkspaceRepository _repository;
  JoinByInviteLinkUsecase(this._repository);

  @override
  Future<Either<Failure, dynamic>> call(String params) {
    return _repository.joinByInviteLink(params);
  }
}

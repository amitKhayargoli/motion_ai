import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/domain/repositories/notes_repository.dart';

class GetWorkspaceNotesParams {
  final String workspaceId;
  final bool forceRefresh;
  const GetWorkspaceNotesParams(this.workspaceId, {this.forceRefresh = false});
}

class GetWorkspaceNotesUseCase
    implements UseCaseWithParams<List<NoteEntity>, GetWorkspaceNotesParams> {
  final INoteRepository repository;

  GetWorkspaceNotesUseCase(this.repository);

  @override
  Future<Either<Failure, List<NoteEntity>>> call(
    GetWorkspaceNotesParams params,
  ) {
    return repository.getWorkspaceNotes(
      params.workspaceId,
      forceRefresh: params.forceRefresh,
    );
  }
}

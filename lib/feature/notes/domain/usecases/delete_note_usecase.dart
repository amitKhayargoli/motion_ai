import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/notes/domain/repositories/notes_repository.dart';

class DeleteNoteParams {
  final String noteId;
  const DeleteNoteParams(this.noteId);
}

class DeleteNoteUseCase implements UseCaseWithParams<bool, DeleteNoteParams> {
  final INoteRepository repository;
  DeleteNoteUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(DeleteNoteParams params) {
    return repository.deleteNote(params.noteId);
  }
}

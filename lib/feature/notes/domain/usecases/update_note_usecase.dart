import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/domain/repositories/notes_repository.dart';

class UpdateNoteParams {
  final String noteId;
  final String title;
  final String content;

  const UpdateNoteParams({
    required this.noteId,
    required this.title,
    required this.content,
  });
}

class UpdateNoteUseCase
    implements UseCaseWithParams<NoteEntity, UpdateNoteParams> {
  final INoteRepository repository;
  UpdateNoteUseCase(this.repository);

  @override
  Future<Either<Failure, NoteEntity>> call(UpdateNoteParams params) {
    return repository.updateNote(params.noteId, params.title, params.content);
  }
}

import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/domain/repositories/notes_repository.dart';

class CreateNoteParams {
  final String workspaceId;
  final String title;
  final String content;

  const CreateNoteParams({
    required this.workspaceId,
    required this.title,
    required this.content,
  });
}

class CreateNoteUseCase
    implements UseCaseWithParams<NoteEntity, CreateNoteParams> {
  final INoteRepository repository;
  CreateNoteUseCase(this.repository);

  @override
  Future<Either<Failure, NoteEntity>> call(CreateNoteParams params) {
    return repository.createNote(
      params.workspaceId,
      params.title,
      params.content,
    );
  }
}

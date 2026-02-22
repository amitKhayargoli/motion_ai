import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import '../entities/note_entity.dart';

abstract class INoteRepository {
  Future<Either<Failure, List<NoteEntity>>> getWorkspaceNotes(
    String workspaceId,
  );

  Future<Either<Failure, NoteEntity>> createNote(
    String workspaceId,
    String title,
    String content,
  );

  Future<Either<Failure, NoteEntity>> updateNote(
    String noteId,
    String title,
    String content,
  );

  Future<Either<Failure, bool>> deleteNote(String noteId);
}

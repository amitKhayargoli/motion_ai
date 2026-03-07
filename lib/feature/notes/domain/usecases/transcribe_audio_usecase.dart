import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/domain/repositories/notes_repository.dart';

class TranscribeAudioParams {
  final String audioFileId;
  final String workspaceId;
  final String? noteTitle;

  const TranscribeAudioParams({
    required this.audioFileId,
    required this.workspaceId,
    this.noteTitle,
  });
}

class TranscribeAudioUseCase
    implements UseCaseWithParams<NoteEntity, TranscribeAudioParams> {
  final INoteRepository repository;
  TranscribeAudioUseCase(this.repository);

  @override
  Future<Either<Failure, NoteEntity>> call(TranscribeAudioParams params) {
    return repository.transcribeAudio(
      audioFileId: params.audioFileId,
      workspaceId: params.workspaceId,
      noteTitle: params.noteTitle,
    );
  }
}

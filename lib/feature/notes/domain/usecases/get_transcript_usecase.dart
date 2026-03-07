import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/domain/repositories/notes_repository.dart';

class GetTranscriptParams {
  final String audioFileId;
  const GetTranscriptParams(this.audioFileId);
}

class GetTranscriptByAudioFileIdUseCase
    implements UseCaseWithParams<NoteEntity?, GetTranscriptParams> {
  final INoteRepository repository;
  GetTranscriptByAudioFileIdUseCase(this.repository);

  @override
  Future<Either<Failure, NoteEntity?>> call(GetTranscriptParams params) {
    return repository.getTranscriptByAudioFileId(params.audioFileId);
  }
}

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/domain/repositories/notes_repository.dart';
import 'package:motion_ai/feature/notes/domain/usecases/transcribe_audio_usecase.dart';

class MockNoteRepository extends Mock implements INoteRepository {}

void main() {
  late TranscribeAudioUseCase usecase;
  late MockNoteRepository mockRepository;

  setUp(() {
    mockRepository = MockNoteRepository();
    usecase = TranscribeAudioUseCase(mockRepository);
  });

  const tAudioFileId = 'audio-123';
  const tWorkspaceId = 'ws-123';
  const tNoteTitle = 'Meeting Recording';

  final tNote = NoteEntity(
    id: 'note-1',
    workspaceId: tWorkspaceId,
    title: tNoteTitle,
    content: 'Transcribed audio content',
    audioFileId: tAudioFileId,
    type: 'VOICE_TRANSCRIPT',
    createdAt: DateTime(2025, 1, 1),
  );

  group('TranscribeAudioUseCase', () {
    test('should return NoteEntity when transcription is successful', () async {
      // arrange
      when(
        () => mockRepository.transcribeAudio(
          audioFileId: tAudioFileId,
          workspaceId: tWorkspaceId,
          noteTitle: tNoteTitle,
        ),
      ).thenAnswer((_) async => Right(tNote));

      // act
      final result = await usecase(
        const TranscribeAudioParams(
          audioFileId: tAudioFileId,
          workspaceId: tWorkspaceId,
          noteTitle: tNoteTitle,
        ),
      );

      // assert
      expect(result, Right(tNote));
      verify(
        () => mockRepository.transcribeAudio(
          audioFileId: tAudioFileId,
          workspaceId: tWorkspaceId,
          noteTitle: tNoteTitle,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should pass null noteTitle when not provided', () async {
      // arrange
      when(
        () => mockRepository.transcribeAudio(
          audioFileId: any(named: 'audioFileId'),
          workspaceId: any(named: 'workspaceId'),
          noteTitle: any(named: 'noteTitle'),
        ),
      ).thenAnswer((_) async => Right(tNote));

      // act
      await usecase(
        const TranscribeAudioParams(
          audioFileId: tAudioFileId,
          workspaceId: tWorkspaceId,
        ),
      );

      // assert
      verify(
        () => mockRepository.transcribeAudio(
          audioFileId: tAudioFileId,
          workspaceId: tWorkspaceId,
          noteTitle: null,
        ),
      ).called(1);
    });

    test('should return failure when transcription fails', () async {
      // arrange
      const failure = ApiFailure(message: 'Transcription failed');
      when(
        () => mockRepository.transcribeAudio(
          audioFileId: any(named: 'audioFileId'),
          workspaceId: any(named: 'workspaceId'),
          noteTitle: any(named: 'noteTitle'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        const TranscribeAudioParams(
          audioFileId: tAudioFileId,
          workspaceId: tWorkspaceId,
        ),
      );

      // assert
      expect(result, const Left(failure));
    });

    test('should return NetworkFailure when there is no internet', () async {
      // arrange
      const failure = NetworkFailure();
      when(
        () => mockRepository.transcribeAudio(
          audioFileId: any(named: 'audioFileId'),
          workspaceId: any(named: 'workspaceId'),
          noteTitle: any(named: 'noteTitle'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        const TranscribeAudioParams(
          audioFileId: tAudioFileId,
          workspaceId: tWorkspaceId,
        ),
      );

      // assert
      expect(result, const Left(failure));
    });
  });
}

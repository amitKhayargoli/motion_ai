import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/domain/repositories/notes_repository.dart';
import 'package:motion_ai/feature/notes/domain/usecases/get_transcript_usecase.dart';

class MockNoteRepository extends Mock implements INoteRepository {}

void main() {
  late GetTranscriptByAudioFileIdUseCase usecase;
  late MockNoteRepository mockRepository;

  setUp(() {
    mockRepository = MockNoteRepository();
    usecase = GetTranscriptByAudioFileIdUseCase(mockRepository);
  });

  const tAudioFileId = 'audio-123';

  final tNote = NoteEntity(
    id: 'note-1',
    workspaceId: 'ws-123',
    title: 'Transcript',
    content: 'Transcribed text content',
    audioFileId: tAudioFileId,
    type: 'VOICE_TRANSCRIPT',
    createdAt: DateTime(2025, 1, 1),
  );

  group('GetTranscriptByAudioFileIdUseCase', () {
    test('should return NoteEntity when transcript exists', () async {
      // arrange
      when(
        () => mockRepository.getTranscriptByAudioFileId(tAudioFileId),
      ).thenAnswer((_) async => Right(tNote));

      // act
      final result = await usecase(const GetTranscriptParams(tAudioFileId));

      // assert
      expect(result, Right(tNote));
      verify(
        () => mockRepository.getTranscriptByAudioFileId(tAudioFileId),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return null when no transcript exists', () async {
      // arrange
      when(
        () => mockRepository.getTranscriptByAudioFileId(tAudioFileId),
      ).thenAnswer((_) async => const Right(null));

      // act
      final result = await usecase(const GetTranscriptParams(tAudioFileId));

      // assert
      expect(result, const Right(null));
    });

    test('should return failure when repository fails', () async {
      // arrange
      const failure = ApiFailure(message: 'Not found', statusCode: 404);
      when(
        () => mockRepository.getTranscriptByAudioFileId(any()),
      ).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(const GetTranscriptParams(tAudioFileId));

      // assert
      expect(result, const Left(failure));
    });

    test('should return NetworkFailure when there is no internet', () async {
      // arrange
      const failure = NetworkFailure();
      when(
        () => mockRepository.getTranscriptByAudioFileId(any()),
      ).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(const GetTranscriptParams(tAudioFileId));

      // assert
      expect(result, const Left(failure));
    });

    test('should pass correct audioFileId to repository', () async {
      // arrange
      when(
        () => mockRepository.getTranscriptByAudioFileId(any()),
      ).thenAnswer((_) async => Right(tNote));

      // act
      await usecase(const GetTranscriptParams(tAudioFileId));

      // assert
      verify(
        () => mockRepository.getTranscriptByAudioFileId(tAudioFileId),
      ).called(1);
    });
  });
}

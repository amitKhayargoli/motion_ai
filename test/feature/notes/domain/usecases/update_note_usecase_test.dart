import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/domain/repositories/notes_repository.dart';
import 'package:motion_ai/feature/notes/domain/usecases/update_note_usecase.dart';

class MockNoteRepository extends Mock implements INoteRepository {}

void main() {
  late UpdateNoteUseCase usecase;
  late MockNoteRepository mockRepository;

  setUp(() {
    mockRepository = MockNoteRepository();
    usecase = UpdateNoteUseCase(mockRepository);
  });

  const tNoteId = 'note-1';
  const tTitle = 'Updated Title';
  const tContent = '<p>Updated Content</p>';

  final tUpdatedNote = NoteEntity(
    id: tNoteId,
    workspaceId: 'ws-123',
    title: tTitle,
    content: tContent,
    updatedAt: DateTime(2025, 1, 2),
  );

  group('UpdateNoteUseCase', () {
    test('should return updated NoteEntity when successful', () async {
      // arrange
      when(
        () => mockRepository.updateNote(tNoteId, tTitle, tContent),
      ).thenAnswer((_) async => Right(tUpdatedNote));

      // act
      final result = await usecase(
        const UpdateNoteParams(
          noteId: tNoteId,
          title: tTitle,
          content: tContent,
        ),
      );

      // assert
      expect(result, Right(tUpdatedNote));
      verify(
        () => mockRepository.updateNote(tNoteId, tTitle, tContent),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when update fails', () async {
      // arrange
      const failure = ApiFailure(message: 'Update failed', statusCode: 500);
      when(
        () => mockRepository.updateNote(any(), any(), any()),
      ).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        const UpdateNoteParams(
          noteId: tNoteId,
          title: tTitle,
          content: tContent,
        ),
      );

      // assert
      expect(result, const Left(failure));
    });

    test('should return NetworkFailure when there is no internet', () async {
      // arrange
      const failure = NetworkFailure();
      when(
        () => mockRepository.updateNote(any(), any(), any()),
      ).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        const UpdateNoteParams(
          noteId: tNoteId,
          title: tTitle,
          content: tContent,
        ),
      );

      // assert
      expect(result, const Left(failure));
    });

    test('should pass correct params to repository', () async {
      // arrange
      when(
        () => mockRepository.updateNote(any(), any(), any()),
      ).thenAnswer((_) async => Right(tUpdatedNote));

      // act
      await usecase(
        const UpdateNoteParams(
          noteId: tNoteId,
          title: tTitle,
          content: tContent,
        ),
      );

      // assert
      verify(
        () => mockRepository.updateNote(tNoteId, tTitle, tContent),
      ).called(1);
    });
  });
}

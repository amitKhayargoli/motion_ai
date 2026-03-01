import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/domain/repositories/notes_repository.dart';
import 'package:motion_ai/feature/notes/domain/usecases/get_workspace_notes_usecase.dart';

class MockNoteRepository extends Mock implements INoteRepository {}

void main() {
  late GetWorkspaceNotesUseCase usecase;
  late MockNoteRepository mockRepository;

  setUp(() {
    mockRepository = MockNoteRepository();
    usecase = GetWorkspaceNotesUseCase(mockRepository);
  });

  const tWorkspaceId = 'ws-123';

  final tNotes = [
    NoteEntity(
      id: 'note-1',
      workspaceId: tWorkspaceId,
      title: 'Note 1',
      content: 'Content 1',
      createdAt: DateTime(2025, 1, 1),
    ),
    NoteEntity(
      id: 'note-2',
      workspaceId: tWorkspaceId,
      title: 'Note 2',
      content: 'Content 2',
      createdAt: DateTime(2025, 1, 2),
    ),
  ];

  group('GetWorkspaceNotesUseCase', () {
    test('should return list of notes when successful', () async {
      // arrange
      when(
        () => mockRepository.getWorkspaceNotes(tWorkspaceId),
      ).thenAnswer((_) async => Right(tNotes));

      // act
      final result = await usecase(
        const GetWorkspaceNotesParams(tWorkspaceId),
      );

      // assert
      expect(result, Right(tNotes));
      verify(() => mockRepository.getWorkspaceNotes(tWorkspaceId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return empty list when workspace has no notes', () async {
      // arrange
      when(
        () => mockRepository.getWorkspaceNotes(tWorkspaceId),
      ).thenAnswer((_) async => const Right([]));

      // act
      final result = await usecase(
        const GetWorkspaceNotesParams(tWorkspaceId),
      );

      // assert
      expect(result, const Right(<NoteEntity>[]));
    });

    test('should pass forceRefresh to repository', () async {
      // arrange
      when(
        () => mockRepository.getWorkspaceNotes(
          tWorkspaceId,
          forceRefresh: true,
        ),
      ).thenAnswer((_) async => Right(tNotes));

      // act
      await usecase(
        const GetWorkspaceNotesParams(tWorkspaceId, forceRefresh: true),
      );

      // assert
      verify(
        () => mockRepository.getWorkspaceNotes(
          tWorkspaceId,
          forceRefresh: true,
        ),
      ).called(1);
    });

    test('should return failure when repository fails', () async {
      // arrange
      const failure = ApiFailure(message: 'Unauthorized', statusCode: 401);
      when(
        () => mockRepository.getWorkspaceNotes(any()),
      ).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        const GetWorkspaceNotesParams(tWorkspaceId),
      );

      // assert
      expect(result, const Left(failure));
    });

    test('should return NetworkFailure when there is no internet', () async {
      // arrange
      const failure = NetworkFailure();
      when(
        () => mockRepository.getWorkspaceNotes(any()),
      ).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        const GetWorkspaceNotesParams(tWorkspaceId),
      );

      // assert
      expect(result, const Left(failure));
    });
  });
}

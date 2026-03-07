import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/domain/repositories/notes_repository.dart';
import 'package:motion_ai/feature/notes/domain/usecases/create_notes_usecase.dart';

class MockNoteRepository extends Mock implements INoteRepository {}

void main() {
  late CreateNoteUseCase usecase;
  late MockNoteRepository mockRepository;

  setUp(() {
    mockRepository = MockNoteRepository();
    usecase = CreateNoteUseCase(mockRepository);
  });

  const tWorkspaceId = 'ws-123';
  const tTitle = 'Test Note';
  const tContent = '<p>Hello World</p>';

  final tNote = NoteEntity(
    id: 'note-1',
    workspaceId: tWorkspaceId,
    title: tTitle,
    content: tContent,
    createdAt: DateTime(2025, 1, 1),
  );

  group('CreateNoteUseCase', () {
    test('should return NoteEntity when creation is successful', () async {
      // arrange
      when(
        () => mockRepository.createNote(tWorkspaceId, tTitle, tContent),
      ).thenAnswer((_) async => Right(tNote));

      // act
      final result = await usecase(
        const CreateNoteParams(
          workspaceId: tWorkspaceId,
          title: tTitle,
          content: tContent,
        ),
      );

      // assert
      expect(result, Right(tNote));
      verify(
        () => mockRepository.createNote(tWorkspaceId, tTitle, tContent),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when creation fails', () async {
      // arrange
      const failure = ApiFailure(message: 'Server error', statusCode: 500);
      when(
        () => mockRepository.createNote(any(), any(), any()),
      ).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        const CreateNoteParams(
          workspaceId: tWorkspaceId,
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
        () => mockRepository.createNote(any(), any(), any()),
      ).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        const CreateNoteParams(
          workspaceId: tWorkspaceId,
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
        () => mockRepository.createNote(any(), any(), any()),
      ).thenAnswer((_) async => Right(tNote));

      // act
      await usecase(
        const CreateNoteParams(
          workspaceId: tWorkspaceId,
          title: tTitle,
          content: tContent,
        ),
      );

      // assert
      verify(
        () => mockRepository.createNote(tWorkspaceId, tTitle, tContent),
      ).called(1);
    });
  });
}

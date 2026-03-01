import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/notes/domain/repositories/notes_repository.dart';
import 'package:motion_ai/feature/notes/domain/usecases/delete_note_usecase.dart';

class MockNoteRepository extends Mock implements INoteRepository {}

void main() {
  late DeleteNoteUseCase usecase;
  late MockNoteRepository mockRepository;

  setUp(() {
    mockRepository = MockNoteRepository();
    usecase = DeleteNoteUseCase(mockRepository);
  });

  const tNoteId = 'note-1';

  group('DeleteNoteUseCase', () {
    test('should return true when deletion is successful', () async {
      // arrange
      when(
        () => mockRepository.deleteNote(tNoteId),
      ).thenAnswer((_) async => const Right(true));

      // act
      final result = await usecase(const DeleteNoteParams(tNoteId));

      // assert
      expect(result, const Right(true));
      verify(() => mockRepository.deleteNote(tNoteId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when deletion fails', () async {
      // arrange
      const failure = ApiFailure(message: 'Not found', statusCode: 404);
      when(
        () => mockRepository.deleteNote(any()),
      ).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(const DeleteNoteParams(tNoteId));

      // assert
      expect(result, const Left(failure));
    });

    test('should return NetworkFailure when there is no internet', () async {
      // arrange
      const failure = NetworkFailure();
      when(
        () => mockRepository.deleteNote(any()),
      ).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(const DeleteNoteParams(tNoteId));

      // assert
      expect(result, const Left(failure));
    });

    test('should pass correct noteId to repository', () async {
      // arrange
      when(
        () => mockRepository.deleteNote(any()),
      ).thenAnswer((_) async => const Right(true));

      // act
      await usecase(const DeleteNoteParams(tNoteId));

      // assert
      verify(() => mockRepository.deleteNote(tNoteId)).called(1);
    });
  });
}

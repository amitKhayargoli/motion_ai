import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/tasks/domain/repositories/task_repository.dart';
import 'package:motion_ai/feature/tasks/domain/usecases/delete_task_usecase.dart';

class MockTaskRepository extends Mock implements ITaskRepository {}

void main() {
  late DeleteTaskUseCase usecase;
  late MockTaskRepository mockRepository;

  setUp(() {
    mockRepository = MockTaskRepository();
    usecase = DeleteTaskUseCase(mockRepository);
  });

  const tTaskId = 'task-123';

  group('DeleteTaskUseCase', () {
    test('should return true on success', () async {
      // arrange
      when(() => mockRepository.deleteTask(any()))
          .thenAnswer((_) async => const Right(true));

      // act
      final result = await usecase(const DeleteTaskParams(tTaskId));

      // assert
      expect(result, const Right(true));
      verify(() => mockRepository.deleteTask(tTaskId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should pass correct task id to repository', () async {
      // arrange
      when(() => mockRepository.deleteTask(any()))
          .thenAnswer((_) async => const Right(true));

      // act
      await usecase(const DeleteTaskParams('task-other'));

      // assert
      verify(() => mockRepository.deleteTask('task-other')).called(1);
    });

    test('should return ApiFailure on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Delete failed', statusCode: 403);
      when(() => mockRepository.deleteTask(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(const DeleteTaskParams(tTaskId));

      // assert
      expect(result, const Left(failure));
    });

    test('should return NetworkFailure on network error', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockRepository.deleteTask(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(const DeleteTaskParams(tTaskId));

      // assert
      expect(result, const Left(failure));
    });
  });
}

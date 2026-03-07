import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/tasks/domain/entities/task_entity.dart';
import 'package:motion_ai/feature/tasks/domain/repositories/task_repository.dart';
import 'package:motion_ai/feature/tasks/domain/usecases/update_task_usecase.dart';

class MockTaskRepository extends Mock implements ITaskRepository {}

void main() {
  late UpdateTaskUseCase usecase;
  late MockTaskRepository mockRepository;

  setUp(() {
    mockRepository = MockTaskRepository();
    usecase = UpdateTaskUseCase(mockRepository);
  });

  const tTaskId = 'task-123';

  final tUpdatedTask = TaskEntity(
    id: tTaskId,
    workspaceId: 'ws-1',
    title: 'Updated Title',
    isCompleted: true,
    updatedAt: DateTime(2025, 2, 1),
  );

  group('UpdateTaskUseCase', () {
    test('should return updated task on success', () async {
      // arrange
      when(() => mockRepository.updateTask(
            any(),
            title: any(named: 'title'),
            description: any(named: 'description'),
            isCompleted: any(named: 'isCompleted'),
            priority: any(named: 'priority'),
            dueDate: any(named: 'dueDate'),
          )).thenAnswer((_) async => Right(tUpdatedTask));

      // act
      final result = await usecase(
        const UpdateTaskParams(taskId: tTaskId, title: 'Updated Title'),
      );

      // assert
      expect(result.isRight(), true);
      verify(() => mockRepository.updateTask(
            tTaskId,
            title: 'Updated Title',
            description: null,
            isCompleted: null,
            priority: null,
            dueDate: null,
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should pass all optional params to repository', () async {
      // arrange
      final dueDate = DateTime(2025, 6, 1);
      when(() => mockRepository.updateTask(
            any(),
            title: any(named: 'title'),
            description: any(named: 'description'),
            isCompleted: any(named: 'isCompleted'),
            priority: any(named: 'priority'),
            dueDate: any(named: 'dueDate'),
          )).thenAnswer((_) async => Right(tUpdatedTask));

      // act
      await usecase(UpdateTaskParams(
        taskId: tTaskId,
        title: 'New',
        description: 'Desc',
        isCompleted: true,
        priority: 'HIGH',
        dueDate: dueDate,
      ));

      // assert
      verify(() => mockRepository.updateTask(
            tTaskId,
            title: 'New',
            description: 'Desc',
            isCompleted: true,
            priority: 'HIGH',
            dueDate: dueDate,
          )).called(1);
    });

    test('should return ApiFailure on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Update failed', statusCode: 400);
      when(() => mockRepository.updateTask(
            any(),
            title: any(named: 'title'),
            description: any(named: 'description'),
            isCompleted: any(named: 'isCompleted'),
            priority: any(named: 'priority'),
            dueDate: any(named: 'dueDate'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        const UpdateTaskParams(taskId: tTaskId, isCompleted: true),
      );

      // assert
      expect(result, const Left(failure));
    });

    test('should return NetworkFailure on network error', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockRepository.updateTask(
            any(),
            title: any(named: 'title'),
            description: any(named: 'description'),
            isCompleted: any(named: 'isCompleted'),
            priority: any(named: 'priority'),
            dueDate: any(named: 'dueDate'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        const UpdateTaskParams(taskId: tTaskId),
      );

      // assert
      expect(result, const Left(failure));
    });
  });
}

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/tasks/domain/entities/task_entity.dart';
import 'package:motion_ai/feature/tasks/domain/repositories/task_repository.dart';
import 'package:motion_ai/feature/tasks/domain/usecases/create_task_usecase.dart';

class MockTaskRepository extends Mock implements ITaskRepository {}

void main() {
  late CreateTaskUseCase usecase;
  late MockTaskRepository mockRepository;

  setUp(() {
    mockRepository = MockTaskRepository();
    usecase = CreateTaskUseCase(mockRepository);
  });

  const tWorkspaceId = 'ws-123';
  const tTitle = 'My Task';

  final tTask = TaskEntity(
    id: 'task-1',
    workspaceId: tWorkspaceId,
    title: tTitle,
    createdAt: DateTime(2025, 1, 1),
  );

  group('CreateTaskUseCase', () {
    test('should return task on success', () async {
      // arrange
      when(() => mockRepository.createTask(
            any(),
            any(),
            description: any(named: 'description'),
            priority: any(named: 'priority'),
            dueDate: any(named: 'dueDate'),
          )).thenAnswer((_) async => Right(tTask));

      // act
      final result = await usecase(
        const CreateTaskParams(workspaceId: tWorkspaceId, title: tTitle),
      );

      // assert
      expect(result.isRight(), true);
      verify(() => mockRepository.createTask(
            tWorkspaceId,
            tTitle,
            description: null,
            priority: null,
            dueDate: null,
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should pass all optional params to repository', () async {
      // arrange
      final dueDate = DateTime(2025, 6, 1);
      when(() => mockRepository.createTask(
            any(),
            any(),
            description: any(named: 'description'),
            priority: any(named: 'priority'),
            dueDate: any(named: 'dueDate'),
          )).thenAnswer((_) async => Right(tTask));

      // act
      await usecase(CreateTaskParams(
        workspaceId: tWorkspaceId,
        title: tTitle,
        description: 'A description',
        priority: 'HIGH',
        dueDate: dueDate,
      ));

      // assert
      verify(() => mockRepository.createTask(
            tWorkspaceId,
            tTitle,
            description: 'A description',
            priority: 'HIGH',
            dueDate: dueDate,
          )).called(1);
    });

    test('should return ApiFailure on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Create failed', statusCode: 400);
      when(() => mockRepository.createTask(
            any(),
            any(),
            description: any(named: 'description'),
            priority: any(named: 'priority'),
            dueDate: any(named: 'dueDate'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        const CreateTaskParams(workspaceId: tWorkspaceId, title: tTitle),
      );

      // assert
      expect(result, const Left(failure));
    });

    test('should return NetworkFailure on network error', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockRepository.createTask(
            any(),
            any(),
            description: any(named: 'description'),
            priority: any(named: 'priority'),
            dueDate: any(named: 'dueDate'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        const CreateTaskParams(workspaceId: tWorkspaceId, title: tTitle),
      );

      // assert
      expect(result, const Left(failure));
    });
  });
}

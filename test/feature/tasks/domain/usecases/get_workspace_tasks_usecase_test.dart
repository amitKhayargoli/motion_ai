import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/tasks/domain/entities/task_entity.dart';
import 'package:motion_ai/feature/tasks/domain/repositories/task_repository.dart';
import 'package:motion_ai/feature/tasks/domain/usecases/get_workspace_tasks_usecase.dart';

class MockTaskRepository extends Mock implements ITaskRepository {}

void main() {
  late GetWorkspaceTasksUseCase usecase;
  late MockTaskRepository mockRepository;

  setUp(() {
    mockRepository = MockTaskRepository();
    usecase = GetWorkspaceTasksUseCase(mockRepository);
  });

  const tWorkspaceId = 'ws-123';

  final tTasks = [
    TaskEntity(
      id: 'task-1',
      workspaceId: tWorkspaceId,
      title: 'Task 1',
      createdAt: DateTime(2025, 1, 1),
    ),
    TaskEntity(
      id: 'task-2',
      workspaceId: tWorkspaceId,
      title: 'Task 2',
      createdAt: DateTime(2025, 1, 2),
    ),
  ];

  group('GetWorkspaceTasksUseCase', () {
    test('should return list of tasks on success', () async {
      // arrange
      when(() => mockRepository.getWorkspaceTasks(
            any(),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => Right(tTasks));

      // act
      final result = await usecase(const GetWorkspaceTasksParams(tWorkspaceId));

      // assert
      expect(result.isRight(), true);
      result.fold((_) {}, (tasks) => expect(tasks.length, 2));
      verify(() => mockRepository.getWorkspaceTasks(
            tWorkspaceId,
            forceRefresh: false,
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return empty list on success with no tasks', () async {
      // arrange
      when(() => mockRepository.getWorkspaceTasks(
            any(),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => const Right([]));

      // act
      final result = await usecase(const GetWorkspaceTasksParams(tWorkspaceId));

      // assert
      result.fold((_) {}, (tasks) => expect(tasks, isEmpty));
    });

    test('should pass forceRefresh=true when specified', () async {
      // arrange
      when(() => mockRepository.getWorkspaceTasks(
            any(),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => Right(tTasks));

      // act
      await usecase(
        const GetWorkspaceTasksParams(tWorkspaceId, forceRefresh: true),
      );

      // assert
      verify(() => mockRepository.getWorkspaceTasks(
            tWorkspaceId,
            forceRefresh: true,
          )).called(1);
    });

    test('should return ApiFailure on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Server error', statusCode: 500);
      when(() => mockRepository.getWorkspaceTasks(
            any(),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(const GetWorkspaceTasksParams(tWorkspaceId));

      // assert
      expect(result, const Left(failure));
    });

    test('should return NetworkFailure on network error', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockRepository.getWorkspaceTasks(
            any(),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(const GetWorkspaceTasksParams(tWorkspaceId));

      // assert
      expect(result, const Left(failure));
    });
  });
}

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/tasks/domain/entities/task_entity.dart';
import 'package:motion_ai/feature/tasks/domain/usecases/create_task_usecase.dart';
import 'package:motion_ai/feature/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:motion_ai/feature/tasks/domain/usecases/get_workspace_tasks_usecase.dart';
import 'package:motion_ai/feature/tasks/domain/usecases/update_task_usecase.dart';
import 'package:motion_ai/feature/tasks/presentation/providers/tasks_providers.dart';
import 'package:motion_ai/feature/tasks/presentation/state/tasks_state.dart';
import 'package:motion_ai/feature/tasks/presentation/view_model/tasks_view_model.dart';

// --- Mocks ---
class MockGetWorkspaceTasksUseCase extends Mock
    implements GetWorkspaceTasksUseCase {}

class MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}

class MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase {}

class MockDeleteTaskUseCase extends Mock implements DeleteTaskUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(const GetWorkspaceTasksParams(''));
    registerFallbackValue(
      const CreateTaskParams(workspaceId: '', title: ''),
    );
    registerFallbackValue(const UpdateTaskParams(taskId: ''));
    registerFallbackValue(const DeleteTaskParams(''));
  });

  late MockGetWorkspaceTasksUseCase mockGetTasks;
  late MockCreateTaskUseCase mockCreateTask;
  late MockUpdateTaskUseCase mockUpdateTask;
  late MockDeleteTaskUseCase mockDeleteTask;
  late ProviderContainer container;

  const tWorkspaceId = 'ws-123';

  final tTask1 = TaskEntity(
    id: 'task-1',
    workspaceId: tWorkspaceId,
    title: 'Task 1',
    description: 'Description 1',
    priority: 'HIGH',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  final tTask2 = TaskEntity(
    id: 'task-2',
    workspaceId: tWorkspaceId,
    title: 'Task 2',
    createdAt: DateTime(2025, 1, 2),
    updatedAt: DateTime(2025, 1, 2),
  );

  setUp(() {
    mockGetTasks = MockGetWorkspaceTasksUseCase();
    mockCreateTask = MockCreateTaskUseCase();
    mockUpdateTask = MockUpdateTaskUseCase();
    mockDeleteTask = MockDeleteTaskUseCase();

    container = ProviderContainer(
      overrides: [
        getWorkspaceTasksUseCaseProvider.overrideWithValue(mockGetTasks),
        createTaskUseCaseProvider.overrideWithValue(mockCreateTask),
        updateTaskUseCaseProvider.overrideWithValue(mockUpdateTask),
        deleteTaskUseCaseProvider.overrideWithValue(mockDeleteTask),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  TasksState readState() => container.read(tasksViewModelProvider);
  TasksViewModel readNotifier() =>
      container.read(tasksViewModelProvider.notifier);

  // --- initial state ---

  group('initial state', () {
    test('should have correct initial values', () {
      final state = readState();
      expect(state.status, TasksStatus.initial);
      expect(state.tasks, isEmpty);
      expect(state.workspaceId, isNull);
      expect(state.error, isNull);
    });
  });

  // --- fetchWorkspaceTasks ---

  group('fetchWorkspaceTasks', () {
    test('should set state to loaded with sorted tasks on success', () async {
      // arrange
      when(() => mockGetTasks(any()))
          .thenAnswer((_) async => Right([tTask1, tTask2]));

      // act
      final result = await readNotifier().fetchWorkspaceTasks(tWorkspaceId);

      // assert
      expect(result, true);
      final state = readState();
      expect(state.status, TasksStatus.loaded);
      expect(state.tasks.length, 2);
      // newest first (task2 has later date)
      expect(state.tasks.first.id, 'task-2');
      expect(state.workspaceId, tWorkspaceId);
      expect(state.error, isNull);
    });

    test('should set state to error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Server error');
      when(() => mockGetTasks(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await readNotifier().fetchWorkspaceTasks(tWorkspaceId);

      // assert
      expect(result, false);
      expect(readState().status, TasksStatus.error);
      expect(readState().error, 'Server error');
    });

    test('should re-fetch even when same workspace is already loaded',
        () async {
      // arrange — first load
      when(() => mockGetTasks(any())).thenAnswer((_) async => Right([tTask1]));
      await readNotifier().fetchWorkspaceTasks(tWorkspaceId);
      expect(readState().status, TasksStatus.loaded);

      // act — second call with same workspace
      final result = await readNotifier().fetchWorkspaceTasks(tWorkspaceId);

      // assert — always fetches; no skip optimisation
      expect(result, true);
      verify(() => mockGetTasks(any())).called(2);
    });

    test('should refetch when workspace id changes', () async {
      // arrange — first load
      when(() => mockGetTasks(any())).thenAnswer((_) async => Right([tTask1]));
      await readNotifier().fetchWorkspaceTasks(tWorkspaceId);

      // act — different workspace
      await readNotifier().fetchWorkspaceTasks('ws-456');

      // assert
      verify(() => mockGetTasks(any())).called(2);
    });

    test('should set loading before the call', () async {
      // arrange
      TasksStatus? capturedStatus;
      when(() => mockGetTasks(any())).thenAnswer((_) async {
        capturedStatus = readState().status;
        return Right([tTask1]);
      });

      // act
      await readNotifier().fetchWorkspaceTasks(tWorkspaceId);

      // assert
      expect(capturedStatus, TasksStatus.loading);
    });

    test('should pass correct params to usecase', () async {
      // arrange
      when(() => mockGetTasks(any())).thenAnswer((_) async => const Right([]));

      // act
      await readNotifier().fetchWorkspaceTasks(tWorkspaceId);

      // assert
      final captured = verify(() => mockGetTasks(captureAny())).captured;
      expect(captured.length, 1);
      final params = captured.first as GetWorkspaceTasksParams;
      expect(params.workspaceId, tWorkspaceId);
      expect(params.forceRefresh, false);
    });
  });

  // --- refreshWorkspaceTasks ---

  group('refreshWorkspaceTasks', () {
    test('should set state to loaded with tasks on success', () async {
      // arrange
      when(() => mockGetTasks(any())).thenAnswer((_) async => Right([tTask1]));

      // act
      final result = await readNotifier().refreshWorkspaceTasks(tWorkspaceId);

      // assert
      expect(result, true);
      expect(readState().status, TasksStatus.loaded);
      expect(readState().tasks.length, 1);
    });

    test('should pass forceRefresh=true to usecase', () async {
      // arrange
      when(() => mockGetTasks(any())).thenAnswer((_) async => const Right([]));

      // act
      await readNotifier().refreshWorkspaceTasks(tWorkspaceId);

      // assert
      final captured = verify(() => mockGetTasks(captureAny())).captured;
      expect(captured.length, 1);
      final params = captured.first as GetWorkspaceTasksParams;
      expect(params.workspaceId, tWorkspaceId);
      expect(params.forceRefresh, true);
    });

    test('should set state to error on failure', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockGetTasks(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await readNotifier().refreshWorkspaceTasks(tWorkspaceId);

      // assert
      expect(result, false);
      expect(readState().status, TasksStatus.error);
      expect(readState().error, 'Network connection failed');
    });
  });

  // --- createTask ---

  group('createTask', () {
    test('should prepend new task to list and return it on success', () async {
      // arrange — start with one existing task
      when(() => mockGetTasks(any())).thenAnswer((_) async => Right([tTask1]));
      await readNotifier().fetchWorkspaceTasks(tWorkspaceId);

      final newTask = TaskEntity(
        id: 'task-new',
        workspaceId: tWorkspaceId,
        title: 'New Task',
        createdAt: DateTime(2025, 2, 1),
      );
      when(() => mockCreateTask(any())).thenAnswer((_) async => Right(newTask));

      // act
      final result = await readNotifier().createTask(
        workspaceId: tWorkspaceId,
        title: 'New Task',
      );

      // assert
      expect(result, isNotNull);
      expect(result!.id, 'task-new');
      final state = readState();
      expect(state.status, TasksStatus.loaded);
      expect(state.tasks.first.id, 'task-new'); // prepended
      expect(state.tasks.length, 2);
    });

    test('should return null and set error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Create failed');
      when(() => mockCreateTask(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await readNotifier().createTask(
        workspaceId: tWorkspaceId,
        title: 'Title',
      );

      // assert
      expect(result, isNull);
      expect(readState().status, TasksStatus.error);
      expect(readState().error, 'Create failed');
    });

    test('should set status to creating before the call', () async {
      // arrange
      TasksStatus? capturedStatus;
      when(() => mockCreateTask(any())).thenAnswer((_) async {
        capturedStatus = readState().status;
        return Right(tTask1);
      });

      // act
      await readNotifier().createTask(
        workspaceId: tWorkspaceId,
        title: 'Title',
      );

      // assert
      expect(capturedStatus, TasksStatus.creating);
    });

    test('should pass correct params to usecase', () async {
      // arrange
      final dueDate = DateTime(2025, 6, 1);
      when(() => mockCreateTask(any())).thenAnswer((_) async => Right(tTask1));

      // act
      await readNotifier().createTask(
        workspaceId: tWorkspaceId,
        title: 'My Task',
        description: 'Desc',
        priority: 'HIGH',
        dueDate: dueDate,
      );

      // assert
      final captured = verify(() => mockCreateTask(captureAny())).captured;
      expect(captured.length, 1);
      final params = captured.first as CreateTaskParams;
      expect(params.workspaceId, tWorkspaceId);
      expect(params.title, 'My Task');
      expect(params.description, 'Desc');
      expect(params.priority, 'HIGH');
      expect(params.dueDate, dueDate);
    });
  });

  // --- updateTask (optimistic) ---

  group('updateTask', () {
    test('should optimistically update task in list', () async {
      // arrange — load tasks
      when(() => mockGetTasks(any()))
          .thenAnswer((_) async => Right([tTask1, tTask2]));
      await readNotifier().fetchWorkspaceTasks(tWorkspaceId);

      // Stub update usecase (runs in background) — return server response
      // with the updated title so it doesn't overwrite the optimistic state.
      when(() => mockUpdateTask(any())).thenAnswer(
          (_) async => Right(tTask1.copyWith(title: 'Updated Title')));

      // act
      final result = await readNotifier().updateTask(
        taskId: 'task-1',
        title: 'Updated Title',
      );

      // Wait for background sync to settle
      await Future.delayed(Duration.zero);

      // assert
      expect(result, isNotNull);
      expect(result!.title, 'Updated Title');
      final updated = readState().tasks.firstWhere((t) => t.id == 'task-1');
      expect(updated.title, 'Updated Title');
      expect(readState().tasks.length, 2); // same count
    });

    test('should return null if task not found', () async {
      // arrange — load tasks
      when(() => mockGetTasks(any())).thenAnswer((_) async => Right([tTask1]));
      await readNotifier().fetchWorkspaceTasks(tWorkspaceId);

      // act
      final result = await readNotifier().updateTask(
        taskId: 'nonexistent',
        title: 'Title',
      );

      // assert
      expect(result, isNull);
    });

    test('should update isCompleted optimistically', () async {
      // arrange
      when(() => mockGetTasks(any())).thenAnswer((_) async => Right([tTask1]));
      await readNotifier().fetchWorkspaceTasks(tWorkspaceId);

      when(() => mockUpdateTask(any()))
          .thenAnswer((_) async => Right(tTask1.copyWith(isCompleted: true)));

      // act
      final result = await readNotifier().updateTask(
        taskId: 'task-1',
        isCompleted: true,
      );

      // assert
      expect(result!.isCompleted, true);
      final stateTask = readState().tasks.firstWhere((t) => t.id == 'task-1');
      expect(stateTask.isCompleted, true);
    });

    test('should fire background sync after optimistic update', () async {
      // arrange
      when(() => mockGetTasks(any())).thenAnswer((_) async => Right([tTask1]));
      await readNotifier().fetchWorkspaceTasks(tWorkspaceId);

      when(() => mockUpdateTask(any())).thenAnswer((_) async => Right(tTask1));

      // act
      await readNotifier().updateTask(
        taskId: 'task-1',
        title: 'New Title',
      );

      // Wait for background sync to complete
      await Future.delayed(Duration.zero);

      // assert
      verify(() => mockUpdateTask(any())).called(1);
    });
  });

  // --- deleteTask (optimistic) ---

  group('deleteTask', () {
    test('should optimistically remove task from list', () async {
      // arrange — load tasks
      when(() => mockGetTasks(any()))
          .thenAnswer((_) async => Right([tTask1, tTask2]));
      await readNotifier().fetchWorkspaceTasks(tWorkspaceId);
      expect(readState().tasks.length, 2);

      when(() => mockDeleteTask(any()))
          .thenAnswer((_) async => const Right(true));

      // act
      final result = await readNotifier().deleteTask('task-1');

      // assert
      expect(result, true);
      expect(readState().tasks.length, 1);
      expect(readState().tasks.first.id, 'task-2');
    });

    test('should return true even when task not in list', () async {
      // act
      when(() => mockDeleteTask(any()))
          .thenAnswer((_) async => const Right(true));

      final result = await readNotifier().deleteTask('nonexistent');

      // assert
      expect(result, true);
    });

    test('should fire background sync after optimistic delete', () async {
      // arrange
      when(() => mockGetTasks(any())).thenAnswer((_) async => Right([tTask1]));
      await readNotifier().fetchWorkspaceTasks(tWorkspaceId);

      when(() => mockDeleteTask(any()))
          .thenAnswer((_) async => const Right(true));

      // act
      await readNotifier().deleteTask('task-1');

      // Wait for background sync
      await Future.delayed(Duration.zero);

      // assert
      verify(() => mockDeleteTask(any())).called(1);
    });
  });

  // --- clearError ---

  group('clearError', () {
    test('should clear error from state', () async {
      // arrange — put into error state
      const failure = ApiFailure(message: 'some error');
      when(() => mockGetTasks(any()))
          .thenAnswer((_) async => const Left(failure));
      await readNotifier().fetchWorkspaceTasks(tWorkspaceId);
      expect(readState().error, 'some error');

      // act
      readNotifier().clearError();

      // assert
      expect(readState().error, isNull);
    });
  });
}

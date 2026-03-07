import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';
import 'package:motion_ai/feature/workspace/domain/usecases/create_workspace_usecase.dart';
import 'package:motion_ai/feature/workspace/domain/usecases/get_workspace_usecase.dart';
import 'package:motion_ai/feature/workspace/domain/usecases/join_by_invite_link_usecase.dart';
import 'package:motion_ai/feature/workspace/presentation/state/workspace_state.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

// --- Mocks ---
class MockGetWorkspacesUsecase extends Mock implements GetWorkspacesUsecase {}

class MockCreateWorkspaceUsecase extends Mock
    implements CreateWorkspaceUsecase {}

class MockJoinByInviteLinkUsecase extends Mock
    implements JoinByInviteLinkUsecase {}

void main() {
  late MockGetWorkspacesUsecase mockGetWorkspaces;
  late MockCreateWorkspaceUsecase mockCreateWorkspace;
  late MockJoinByInviteLinkUsecase mockJoinByInviteLink;
  late ProviderContainer container;

  final tWorkspace1 = WorkspaceEntity(
    id: 'ws-1',
    name: 'Workspace 1',
    createdAt: DateTime(2025, 1, 1),
  );

  final tWorkspace2 = WorkspaceEntity(
    id: 'ws-2',
    name: 'Workspace 2',
    createdAt: DateTime(2025, 1, 2),
  );

  setUp(() {
    mockGetWorkspaces = MockGetWorkspacesUsecase();
    mockCreateWorkspace = MockCreateWorkspaceUsecase();
    mockJoinByInviteLink = MockJoinByInviteLinkUsecase();

    container = ProviderContainer(
      overrides: [
        getWorkspacesUsecaseProvider.overrideWithValue(mockGetWorkspaces),
        createWorkspaceUsecaseProvider.overrideWithValue(mockCreateWorkspace),
        joinByInviteLinkUsecaseProvider.overrideWithValue(mockJoinByInviteLink),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  WorkspaceState readState() => container.read(workspaceViewModelProvider);
  WorkspaceViewModel readNotifier() =>
      container.read(workspaceViewModelProvider.notifier);

  // --- initial state ---

  group('initial state', () {
    test('should have correct initial values', () {
      final state = readState();
      expect(state.isLoading, false);
      expect(state.workspaces, isEmpty);
      expect(state.selected, isNull);
      expect(state.error, isNull);
    });
  });

  // --- fetchMyWorkspaces ---

  group('fetchMyWorkspaces', () {
    test('should return true and set workspaces on success', () async {
      // arrange
      when(() => mockGetWorkspaces())
          .thenAnswer((_) async => Right([tWorkspace1, tWorkspace2]));

      // act
      final result = await readNotifier().fetchMyWorkspaces();

      // assert
      expect(result, true);
      final state = readState();
      expect(state.isLoading, false);
      expect(state.workspaces.length, 2);
      expect(state.selected?.id, 'ws-1'); // first workspace selected
      expect(state.error, isNull);
    });

    test('should select first workspace when list is not empty', () async {
      // arrange
      when(() => mockGetWorkspaces())
          .thenAnswer((_) async => Right([tWorkspace2, tWorkspace1]));

      // act
      await readNotifier().fetchMyWorkspaces();

      // assert
      expect(readState().selected?.id, 'ws-2');
    });

    test('should set selected to null when list is empty', () async {
      // arrange
      when(() => mockGetWorkspaces()).thenAnswer((_) async => const Right([]));

      // act
      await readNotifier().fetchMyWorkspaces();

      // assert
      expect(readState().selected, isNull);
      expect(readState().workspaces, isEmpty);
    });

    test('should return false and set error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Server error', statusCode: 500);
      when(() => mockGetWorkspaces())
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await readNotifier().fetchMyWorkspaces();

      // assert
      expect(result, false);
      final state = readState();
      expect(state.isLoading, false);
      expect(state.error, 'Server error');
    });

    test('should set isLoading to true before the call', () async {
      // arrange
      bool? capturedLoading;
      when(() => mockGetWorkspaces()).thenAnswer((_) async {
        capturedLoading = readState().isLoading;
        return Right([tWorkspace1]);
      });

      // act
      await readNotifier().fetchMyWorkspaces();

      // assert
      expect(capturedLoading, true);
    });

    test('should handle NetworkFailure', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockGetWorkspaces())
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await readNotifier().fetchMyWorkspaces();

      // assert
      expect(result, false);
      expect(readState().error, 'Network connection failed');
    });
  });

  // --- createWorkspace ---

  group('createWorkspace', () {
    test('should return true and prepend workspace on success', () async {
      // arrange — start with one existing workspace
      when(() => mockGetWorkspaces())
          .thenAnswer((_) async => Right([tWorkspace1]));
      await readNotifier().fetchMyWorkspaces();

      final newWorkspace = WorkspaceEntity(
        id: 'ws-new',
        name: 'New Workspace',
        createdAt: DateTime(2025, 2, 1),
      );
      when(() => mockCreateWorkspace(any()))
          .thenAnswer((_) async => Right(newWorkspace));

      // act
      final result = await readNotifier().createWorkspace('New Workspace');

      // assert
      expect(result, true);
      final state = readState();
      expect(state.isLoading, false);
      expect(state.workspaces.length, 2);
      expect(state.workspaces.first.id, 'ws-new'); // prepended
      expect(state.selected?.id, 'ws-new'); // newly created is selected
      expect(state.error, isNull);
    });

    test('should return false and set error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Create failed');
      when(() => mockCreateWorkspace(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await readNotifier().createWorkspace('Name');

      // assert
      expect(result, false);
      expect(readState().error, 'Create failed');
      expect(readState().isLoading, false);
    });

    test('should set isLoading to true before the call', () async {
      // arrange
      bool? capturedLoading;
      when(() => mockCreateWorkspace(any())).thenAnswer((_) async {
        capturedLoading = readState().isLoading;
        return Right(tWorkspace1);
      });

      // act
      await readNotifier().createWorkspace('Name');

      // assert
      expect(capturedLoading, true);
    });

    test('should clear previous error before creating', () async {
      // arrange — first fail
      const failure = ApiFailure(message: 'first error');
      when(() => mockCreateWorkspace(any()))
          .thenAnswer((_) async => const Left(failure));
      await readNotifier().createWorkspace('Name');
      expect(readState().error, 'first error');

      // arrange — capture error during second call
      String? capturedError;
      when(() => mockCreateWorkspace(any())).thenAnswer((_) async {
        capturedError = readState().error;
        return Right(tWorkspace1);
      });

      // act
      await readNotifier().createWorkspace('Name 2');

      // assert
      expect(capturedError, isNull); // error was cleared
    });

    test('should pass correct name to usecase', () async {
      // arrange
      when(() => mockCreateWorkspace(any()))
          .thenAnswer((_) async => Right(tWorkspace1));

      // act
      await readNotifier().createWorkspace('My Workspace');

      // assert
      verify(() => mockCreateWorkspace('My Workspace')).called(1);
    });
  });

  // --- joinByInviteLink ---

  group('joinByInviteLink', () {
    test('should return true and prepend workspace on success', () async {
      // arrange
      when(() => mockGetWorkspaces())
          .thenAnswer((_) async => Right([tWorkspace1]));
      await readNotifier().fetchMyWorkspaces();

      final joinedWorkspace = WorkspaceEntity(
        id: 'ws-joined',
        name: 'Joined Workspace',
        createdAt: DateTime(2025, 2, 1),
      );
      when(() => mockJoinByInviteLink(any()))
          .thenAnswer((_) async => Right(joinedWorkspace));

      // act
      final result = await readNotifier().joinByInviteLink('invite-link');

      // assert
      expect(result, true);
      final state = readState();
      expect(state.workspaces.length, 2);
      expect(state.workspaces.first.id, 'ws-joined'); // prepended
      expect(state.selected?.id, 'ws-joined'); // selected
    });

    test('should not duplicate workspace if already exists', () async {
      // arrange — load workspace1
      when(() => mockGetWorkspaces())
          .thenAnswer((_) async => Right([tWorkspace1]));
      await readNotifier().fetchMyWorkspaces();
      expect(readState().workspaces.length, 1);

      // arrange — join returns same workspace (already a member)
      when(() => mockJoinByInviteLink(any()))
          .thenAnswer((_) async => Right(tWorkspace1));

      // act
      final result = await readNotifier().joinByInviteLink('invite-link');

      // assert
      expect(result, true);
      expect(readState().workspaces.length, 1); // no duplicate
      expect(readState().selected?.id, 'ws-1'); // still selected
    });

    test('should return false and set error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Invalid link', statusCode: 404);
      when(() => mockJoinByInviteLink(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await readNotifier().joinByInviteLink('bad-link');

      // assert
      expect(result, false);
      expect(readState().error, 'Invalid link');
      expect(readState().isLoading, false);
    });

    test('should set isLoading to true before the call', () async {
      // arrange
      bool? capturedLoading;
      when(() => mockJoinByInviteLink(any())).thenAnswer((_) async {
        capturedLoading = readState().isLoading;
        return Right(tWorkspace1);
      });

      // act
      await readNotifier().joinByInviteLink('link');

      // assert
      expect(capturedLoading, true);
    });

    test('should clear previous error before joining', () async {
      // arrange — first fail
      const failure = ApiFailure(message: 'old error');
      when(() => mockJoinByInviteLink(any()))
          .thenAnswer((_) async => const Left(failure));
      await readNotifier().joinByInviteLink('link');
      expect(readState().error, 'old error');

      // arrange — capture error during second call
      String? capturedError;
      when(() => mockJoinByInviteLink(any())).thenAnswer((_) async {
        capturedError = readState().error;
        return Right(tWorkspace1);
      });

      // act
      await readNotifier().joinByInviteLink('link2');

      // assert
      expect(capturedError, isNull); // error was cleared
    });

    test('should pass correct invite link to usecase', () async {
      // arrange
      when(() => mockJoinByInviteLink(any()))
          .thenAnswer((_) async => Right(tWorkspace1));

      // act
      await readNotifier().joinByInviteLink('https://example.com/invite/abc');

      // assert
      verify(() => mockJoinByInviteLink('https://example.com/invite/abc'))
          .called(1);
    });
  });

  // --- selectWorkspace ---

  group('selectWorkspace', () {
    test('should select workspace by id', () async {
      // arrange
      when(() => mockGetWorkspaces())
          .thenAnswer((_) async => Right([tWorkspace1, tWorkspace2]));
      await readNotifier().fetchMyWorkspaces();
      expect(readState().selected?.id, 'ws-1');

      // act
      readNotifier().selectWorkspace('ws-2');

      // assert
      expect(readState().selected?.id, 'ws-2');
    });

    test('should not change selected if workspace id not found', () async {
      // arrange
      when(() => mockGetWorkspaces())
          .thenAnswer((_) async => Right([tWorkspace1]));
      await readNotifier().fetchMyWorkspaces();
      expect(readState().selected?.id, 'ws-1');

      // act
      readNotifier().selectWorkspace('nonexistent');

      // assert
      expect(readState().selected?.id, 'ws-1'); // unchanged
    });
  });

  // --- clearError ---

  group('clearError', () {
    test('should clear error from state', () async {
      // arrange — put into error state
      const failure = ApiFailure(message: 'some error');
      when(() => mockGetWorkspaces())
          .thenAnswer((_) async => const Left(failure));
      await readNotifier().fetchMyWorkspaces();
      expect(readState().error, 'some error');

      // act
      readNotifier().clearError();

      // assert
      expect(readState().error, isNull);
    });
  });
}

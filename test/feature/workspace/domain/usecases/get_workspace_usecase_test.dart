import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';
import 'package:motion_ai/feature/workspace/domain/repositories/workspace_repository.dart';
import 'package:motion_ai/feature/workspace/domain/usecases/get_workspace_usecase.dart';

class MockWorkspaceRepository extends Mock implements IWorkspaceRepository {}

void main() {
  late GetWorkspacesUsecase usecase;
  late MockWorkspaceRepository mockRepository;

  setUp(() {
    mockRepository = MockWorkspaceRepository();
    usecase = GetWorkspacesUsecase(mockRepository);
  });

  final tWorkspaces = [
    WorkspaceEntity(
        id: 'ws-1', name: 'Workspace 1', createdAt: DateTime(2025, 1, 1)),
    WorkspaceEntity(
        id: 'ws-2', name: 'Workspace 2', createdAt: DateTime(2025, 1, 2)),
  ];

  group('GetWorkspacesUsecase', () {
    test('should return list of workspaces on success', () async {
      // arrange
      when(() => mockRepository.getMyWorkspaces())
          .thenAnswer((_) async => Right(tWorkspaces));

      // act
      final result = await usecase();

      // assert
      expect(result, Right(tWorkspaces));
      verify(() => mockRepository.getMyWorkspaces()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return empty list on success with no workspaces', () async {
      // arrange
      when(() => mockRepository.getMyWorkspaces())
          .thenAnswer((_) async => const Right([]));

      // act
      final result = await usecase();

      // assert
      expect(result, const Right(<WorkspaceEntity>[]));
      verify(() => mockRepository.getMyWorkspaces()).called(1);
    });

    test('should return ApiFailure on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Server error', statusCode: 500);
      when(() => mockRepository.getMyWorkspaces())
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase();

      // assert
      expect(result, const Left(failure));
      verify(() => mockRepository.getMyWorkspaces()).called(1);
    });

    test('should return NetworkFailure on network error', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockRepository.getMyWorkspaces())
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase();

      // assert
      expect(result, const Left(failure));
      verify(() => mockRepository.getMyWorkspaces()).called(1);
    });
  });
}

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';
import 'package:motion_ai/feature/workspace/domain/repositories/workspace_repository.dart';
import 'package:motion_ai/feature/workspace/domain/usecases/create_workspace_usecase.dart';

class MockWorkspaceRepository extends Mock implements IWorkspaceRepository {}

void main() {
  late CreateWorkspaceUsecase usecase;
  late MockWorkspaceRepository mockRepository;

  setUp(() {
    mockRepository = MockWorkspaceRepository();
    usecase = CreateWorkspaceUsecase(mockRepository);
  });

  const tName = 'My Workspace';

  final tWorkspace = WorkspaceEntity(
    id: 'ws-1',
    name: tName,
    createdAt: DateTime(2025, 1, 1),
  );

  group('CreateWorkspaceUsecase', () {
    test('should return workspace on success', () async {
      // arrange
      when(() => mockRepository.createWorkspace(any()))
          .thenAnswer((_) async => Right(tWorkspace));

      // act
      final result = await usecase(tName);

      // assert
      expect(result.isRight(), true);
      verify(() => mockRepository.createWorkspace(tName)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should pass correct name parameter to repository', () async {
      // arrange
      when(() => mockRepository.createWorkspace(any()))
          .thenAnswer((_) async => Right(tWorkspace));

      // act
      await usecase('Test Name');

      // assert
      verify(() => mockRepository.createWorkspace('Test Name')).called(1);
    });

    test('should return ApiFailure on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Create failed', statusCode: 400);
      when(() => mockRepository.createWorkspace(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(tName);

      // assert
      expect(result, const Left(failure));
      verify(() => mockRepository.createWorkspace(tName)).called(1);
    });

    test('should return NetworkFailure on network error', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockRepository.createWorkspace(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(tName);

      // assert
      expect(result, const Left(failure));
      verify(() => mockRepository.createWorkspace(tName)).called(1);
    });
  });
}

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/workspace/domain/repositories/workspace_repository.dart';
import 'package:motion_ai/feature/workspace/domain/usecases/delete_workspace_usecase.dart';

class MockWorkspaceRepository extends Mock implements IWorkspaceRepository {}

void main() {
  late DeleteWorkspaceUsecase usecase;
  late MockWorkspaceRepository mockRepository;

  setUp(() {
    mockRepository = MockWorkspaceRepository();
    usecase = DeleteWorkspaceUsecase(mockRepository);
  });

  const tWorkspaceId = 'ws-123';

  group('DeleteWorkspaceUsecase', () {
    test('should return true on success', () async {
      // arrange
      when(() => mockRepository.deleteWorkspace(any()))
          .thenAnswer((_) async => const Right(true));

      // act
      final result = await usecase(tWorkspaceId);

      // assert
      expect(result, const Right(true));
      verify(() => mockRepository.deleteWorkspace(tWorkspaceId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should pass correct workspace id to repository', () async {
      // arrange
      when(() => mockRepository.deleteWorkspace(any()))
          .thenAnswer((_) async => const Right(true));

      // act
      await usecase('ws-456');

      // assert
      verify(() => mockRepository.deleteWorkspace('ws-456')).called(1);
    });

    test('should return ApiFailure on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Delete failed', statusCode: 403);
      when(() => mockRepository.deleteWorkspace(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(tWorkspaceId);

      // assert
      expect(result, const Left(failure));
      verify(() => mockRepository.deleteWorkspace(tWorkspaceId)).called(1);
    });

    test('should return NetworkFailure on network error', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockRepository.deleteWorkspace(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(tWorkspaceId);

      // assert
      expect(result, const Left(failure));
      verify(() => mockRepository.deleteWorkspace(tWorkspaceId)).called(1);
    });
  });
}

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';
import 'package:motion_ai/feature/workspace/domain/repositories/workspace_repository.dart';
import 'package:motion_ai/feature/workspace/domain/usecases/join_by_invite_link_usecase.dart';

class MockWorkspaceRepository extends Mock implements IWorkspaceRepository {}

void main() {
  late JoinByInviteLinkUsecase usecase;
  late MockWorkspaceRepository mockRepository;

  setUp(() {
    mockRepository = MockWorkspaceRepository();
    usecase = JoinByInviteLinkUsecase(mockRepository);
  });

  const tInviteLink = 'https://example.com/invite/abc123';

  final tWorkspace = WorkspaceEntity(
    id: 'ws-joined',
    name: 'Joined Workspace',
    createdAt: DateTime(2025, 1, 1),
  );

  group('JoinByInviteLinkUsecase', () {
    test('should return workspace on success', () async {
      // arrange
      when(() => mockRepository.joinByInviteLink(any()))
          .thenAnswer((_) async => Right(tWorkspace));

      // act
      final result = await usecase(tInviteLink);

      // assert
      expect(result.isRight(), true);
      verify(() => mockRepository.joinByInviteLink(tInviteLink)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should pass correct invite link to repository', () async {
      // arrange
      when(() => mockRepository.joinByInviteLink(any()))
          .thenAnswer((_) async => Right(tWorkspace));

      // act
      await usecase('different-link');

      // assert
      verify(() => mockRepository.joinByInviteLink('different-link')).called(1);
    });

    test('should return ApiFailure on failure', () async {
      // arrange
      const failure =
          ApiFailure(message: 'Invalid invite link', statusCode: 404);
      when(() => mockRepository.joinByInviteLink(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(tInviteLink);

      // assert
      expect(result, const Left(failure));
      verify(() => mockRepository.joinByInviteLink(tInviteLink)).called(1);
    });

    test('should return NetworkFailure on network error', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockRepository.joinByInviteLink(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(tInviteLink);

      // assert
      expect(result, const Left(failure));
      verify(() => mockRepository.joinByInviteLink(tInviteLink)).called(1);
    });
  });
}

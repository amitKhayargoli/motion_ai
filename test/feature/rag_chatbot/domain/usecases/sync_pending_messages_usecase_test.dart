import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/repositories/rag_chatbot_repository.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/usecases/sync_pending_messages_usecase.dart';

class MockRagChatbotRepository extends Mock implements IRagChatbotRepository {}

void main() {
  late SyncPendingMessagesUseCase usecase;
  late MockRagChatbotRepository mockRepository;

  setUp(() {
    mockRepository = MockRagChatbotRepository();
    usecase = SyncPendingMessagesUseCase(mockRepository);
  });

  const tWorkspaceId = 'ws-123';
  const tThreadId = 'thread-123';

  group('SyncPendingMessagesUseCase', () {
    test('should return true on success', () async {
      // arrange
      when(() => mockRepository.syncPendingMessages(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => const Right(true));

      // act
      final result = await usecase(
        SyncPendingParams(workspaceId: tWorkspaceId, threadId: tThreadId),
      );

      // assert
      expect(result, const Right(true));
      verify(() => mockRepository.syncPendingMessages(
            workspaceId: tWorkspaceId,
            threadId: tThreadId,
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should pass correct params to repository', () async {
      // arrange
      when(() => mockRepository.syncPendingMessages(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => const Right(true));

      // act
      await usecase(
        SyncPendingParams(workspaceId: 'ws-other', threadId: 'thread-other'),
      );

      // assert
      verify(() => mockRepository.syncPendingMessages(
            workspaceId: 'ws-other',
            threadId: 'thread-other',
          )).called(1);
    });

    test('should return ApiFailure on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Sync failed', statusCode: 500);
      when(() => mockRepository.syncPendingMessages(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        SyncPendingParams(workspaceId: tWorkspaceId, threadId: tThreadId),
      );

      // assert
      expect(result, const Left(failure));
    });

    test('should return NetworkFailure on network error', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockRepository.syncPendingMessages(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        SyncPendingParams(workspaceId: tWorkspaceId, threadId: tThreadId),
      );

      // assert
      expect(result, const Left(failure));
    });
  });
}

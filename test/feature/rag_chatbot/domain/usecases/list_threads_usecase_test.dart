import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/entities/chat_thread_entity.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/repositories/rag_chatbot_repository.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/usecases/list_threads_usecase.dart';

class MockRagChatbotRepository extends Mock implements IRagChatbotRepository {}

void main() {
  late ListThreadsUseCase usecase;
  late MockRagChatbotRepository mockRepository;

  setUp(() {
    mockRepository = MockRagChatbotRepository();
    usecase = ListThreadsUseCase(mockRepository);
  });

  const tWorkspaceId = 'ws-123';

  final tThreads = [
    ChatThreadEntity(
      id: 'thread-1',
      workspaceId: tWorkspaceId,
      userId: 'user-1',
      title: 'Thread 1',
      messages: const [],
    ),
    ChatThreadEntity(
      id: 'thread-2',
      workspaceId: tWorkspaceId,
      userId: 'user-1',
      title: 'Thread 2',
      messages: const [],
    ),
  ];

  group('ListThreadsUseCase', () {
    test('should return list of threads on success', () async {
      // arrange
      when(() => mockRepository.listThreads(
            workspaceId: any(named: 'workspaceId'),
          )).thenAnswer((_) async => Right(tThreads));

      // act
      final result = await usecase(
        ListThreadsParams(workspaceId: tWorkspaceId),
      );

      // assert
      expect(result.isRight(), true);
      result.fold((_) {}, (threads) => expect(threads.length, 2));
      verify(() => mockRepository.listThreads(
            workspaceId: tWorkspaceId,
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return empty list on success with no threads', () async {
      // arrange
      when(() => mockRepository.listThreads(
            workspaceId: any(named: 'workspaceId'),
          )).thenAnswer((_) async => const Right([]));

      // act
      final result = await usecase(
        ListThreadsParams(workspaceId: tWorkspaceId),
      );

      // assert
      expect(result.isRight(), true);
      result.fold((_) {}, (threads) => expect(threads, isEmpty));
    });

    test('should return ApiFailure on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Server error', statusCode: 500);
      when(() => mockRepository.listThreads(
            workspaceId: any(named: 'workspaceId'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        ListThreadsParams(workspaceId: tWorkspaceId),
      );

      // assert
      expect(result, const Left(failure));
    });

    test('should return NetworkFailure on network error', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockRepository.listThreads(
            workspaceId: any(named: 'workspaceId'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        ListThreadsParams(workspaceId: tWorkspaceId),
      );

      // assert
      expect(result, const Left(failure));
    });
  });
}

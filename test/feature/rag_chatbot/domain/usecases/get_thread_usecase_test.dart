import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/entities/chat_message_entity.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/entities/chat_thread_entity.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/repositories/rag_chatbot_repository.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/usecases/get_thread_usecase.dart';

class MockRagChatbotRepository extends Mock implements IRagChatbotRepository {}

void main() {
  late GetThreadUseCase usecase;
  late MockRagChatbotRepository mockRepository;

  setUp(() {
    mockRepository = MockRagChatbotRepository();
    usecase = GetThreadUseCase(mockRepository);
  });

  const tThreadId = 'thread-123';

  final tThread = ChatThreadEntity(
    id: tThreadId,
    workspaceId: 'ws-1',
    userId: 'user-1',
    title: 'My Thread',
    createdAt: DateTime(2025, 1, 1),
    messages: const [],
  );

  group('GetThreadUseCase', () {
    test('should return thread on success', () async {
      // arrange
      when(() => mockRepository.getThread(
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => Right(tThread));

      // act
      final result = await usecase(GetThreadParams(threadId: tThreadId));

      // assert
      expect(result.isRight(), true);
      result.fold((_) {}, (thread) {
        expect(thread.id, tThreadId);
        expect(thread.title, 'My Thread');
      });
      verify(() => mockRepository.getThread(threadId: tThreadId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should pass correct thread id to repository', () async {
      // arrange
      when(() => mockRepository.getThread(
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => Right(tThread));

      // act
      await usecase(GetThreadParams(threadId: 'thread-other'));

      // assert
      verify(() => mockRepository.getThread(threadId: 'thread-other'))
          .called(1);
    });

    test('should return thread with messages', () async {
      // arrange
      final threadWithMessages = ChatThreadEntity(
        id: tThreadId,
        workspaceId: 'ws-1',
        userId: 'user-1',
        title: 'Thread with msgs',
        messages: const [
          ChatMessageEntity(
            id: 'msg-1',
            threadId: 'thread-123',
            role: 'user',
            content: 'Hello',
          ),
        ],
      );
      when(() => mockRepository.getThread(
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => Right(threadWithMessages));

      // act
      final result = await usecase(GetThreadParams(threadId: tThreadId));

      // assert
      result.fold((_) {}, (thread) {
        expect(thread.messages.length, 1);
        expect(thread.messages.first.content, 'Hello');
      });
    });

    test('should return ApiFailure on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Not found', statusCode: 404);
      when(() => mockRepository.getThread(
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(GetThreadParams(threadId: tThreadId));

      // assert
      expect(result, const Left(failure));
    });

    test('should return NetworkFailure on network error', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockRepository.getThread(
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(GetThreadParams(threadId: tThreadId));

      // assert
      expect(result, const Left(failure));
    });
  });
}

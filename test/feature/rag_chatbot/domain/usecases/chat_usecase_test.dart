import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/entities/chat_message_entity.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/repositories/rag_chatbot_repository.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/usecases/chat_usecase.dart';

class MockRagChatbotRepository extends Mock implements IRagChatbotRepository {}

void main() {
  late ChatUseCase usecase;
  late MockRagChatbotRepository mockRepository;

  setUp(() {
    mockRepository = MockRagChatbotRepository();
    usecase = ChatUseCase(mockRepository);
  });

  const tWorkspaceId = 'ws-123';
  const tThreadId = 'thread-1';
  const tMessage = 'Hello AI';

  final tMessages = [
    const ChatMessageEntity(
      id: 'msg-1',
      threadId: tThreadId,
      role: 'user',
      content: 'Hello AI',
    ),
    const ChatMessageEntity(
      id: 'msg-2',
      threadId: tThreadId,
      role: 'assistant',
      content: 'Hello! How can I help you?',
    ),
  ];

  group('ChatUseCase', () {
    test('should return list of messages on success', () async {
      // arrange
      when(() => mockRepository.chat(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
            message: any(named: 'message'),
          )).thenAnswer((_) async => Right(tMessages));

      // act
      final result = await usecase(ChatParams(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
        message: tMessage,
      ));

      // assert
      expect(result.isRight(), true);
      result.fold((_) {}, (msgs) => expect(msgs.length, 2));
      verify(() => mockRepository.chat(
            workspaceId: tWorkspaceId,
            threadId: tThreadId,
            message: tMessage,
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should pass correct params to repository', () async {
      // arrange
      when(() => mockRepository.chat(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
            message: any(named: 'message'),
          )).thenAnswer((_) async => Right(tMessages));

      // act
      await usecase(ChatParams(
        workspaceId: 'ws-other',
        threadId: 'thread-other',
        message: 'Different message',
      ));

      // assert
      verify(() => mockRepository.chat(
            workspaceId: 'ws-other',
            threadId: 'thread-other',
            message: 'Different message',
          )).called(1);
    });

    test('should return ApiFailure on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Chat failed', statusCode: 500);
      when(() => mockRepository.chat(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
            message: any(named: 'message'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(ChatParams(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
        message: tMessage,
      ));

      // assert
      expect(result, const Left(failure));
    });

    test('should return NetworkFailure on network error', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockRepository.chat(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
            message: any(named: 'message'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(ChatParams(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
        message: tMessage,
      ));

      // assert
      expect(result, const Left(failure));
    });
  });
}

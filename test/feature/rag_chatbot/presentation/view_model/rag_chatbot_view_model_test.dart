import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/entities/chat_message_entity.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/entities/chat_thread_entity.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/repositories/rag_chatbot_repository.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/providers/rag_chatbot_providers.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/state/rag_chatbot_state.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/view_model/rag_chatbot_view_model.dart';

class MockRagChatbotRepository extends Mock implements IRagChatbotRepository {}

void main() {
  late MockRagChatbotRepository mockRepo;
  late ProviderContainer container;

  const tWorkspaceId = 'ws-123';
  const tThreadId = 'thread-1';

  final tThread = ChatThreadEntity(
    id: tThreadId,
    workspaceId: tWorkspaceId,
    userId: 'user-1',
    title: 'New chat',
    createdAt: DateTime(2025, 1, 1),
    messages: const [],
  );

  final tThreadWithMessages = ChatThreadEntity(
    id: tThreadId,
    workspaceId: tWorkspaceId,
    userId: 'user-1',
    title: 'Chat thread',
    createdAt: DateTime(2025, 1, 1),
    messages: const [
      ChatMessageEntity(
        id: 'msg-1',
        threadId: tThreadId,
        role: 'user',
        content: 'Hello',
      ),
      ChatMessageEntity(
        id: 'msg-2',
        threadId: tThreadId,
        role: 'assistant',
        content: 'Hi there!',
      ),
    ],
  );

  final tThread2 = ChatThreadEntity(
    id: 'thread-2',
    workspaceId: tWorkspaceId,
    userId: 'user-1',
    title: 'Thread 2',
    messages: const [],
  );

  setUp(() {
    mockRepo = MockRagChatbotRepository();

    container = ProviderContainer(
      overrides: [
        ragChatbotRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  RagChatbotState readState() => container.read(ragChatbotViewModelProvider);
  RagChatbotViewModel readNotifier() =>
      container.read(ragChatbotViewModelProvider.notifier);

  // --- initial state ---

  group('initial state', () {
    test('should have correct initial values', () {
      final state = readState();
      expect(state.status, RagChatbotStatus.idle);
      expect(state.chatStatus, RagChatStatus.idle);
      expect(state.error, isNull);
      expect(state.activeWorkspaceId, isNull);
      expect(state.activeThreadId, isNull);
      expect(state.messages, isEmpty);
      expect(state.threads, isEmpty);
      expect(state.assistantTyping, false);
    });
  });

  // --- clearError ---

  group('clearError', () {
    test('should clear error from state', () async {
      // arrange — put into error state via startNewThread failure
      const failure = ApiFailure(message: 'some error');
      when(() => mockRepo.createThread(
            workspaceId: any(named: 'workspaceId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async => const Left(failure));
      await readNotifier().startNewThread(workspaceId: tWorkspaceId);
      expect(readState().error, 'some error');

      // act
      readNotifier().clearError();

      // assert
      expect(readState().error, isNull);
    });
  });

  // --- clearChat ---

  group('clearChat', () {
    test('should clear active thread, messages, and typing state', () async {
      // arrange — open a thread first
      when(() => mockRepo.getThread(threadId: any(named: 'threadId')))
          .thenAnswer((_) async => Right(tThreadWithMessages));
      when(() => mockRepo.syncPendingMessages(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => const Right(true));
      await readNotifier().openThread(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
        syncPendingAfterOpen: false,
      );
      expect(readState().activeThreadId, tThreadId);
      expect(readState().messages.length, 2);

      // act
      readNotifier().clearChat();

      // assert
      final state = readState();
      expect(state.activeThreadId, isNull);
      expect(state.messages, isEmpty);
      expect(state.assistantTyping, false);
      expect(state.chatStatus, RagChatStatus.idle);
    });
  });

  // --- startNewThread ---

  group('startNewThread', () {
    test('should set state to ready with thread on success', () async {
      // arrange
      when(() => mockRepo.createThread(
            workspaceId: any(named: 'workspaceId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async => Right(tThread));

      // act
      await readNotifier().startNewThread(workspaceId: tWorkspaceId);

      // assert
      final state = readState();
      expect(state.status, RagChatbotStatus.ready);
      expect(state.activeThreadId, tThreadId);
      expect(state.activeWorkspaceId, tWorkspaceId);
    });

    test('should set state to error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Create failed');
      when(() => mockRepo.createThread(
            workspaceId: any(named: 'workspaceId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().startNewThread(workspaceId: tWorkspaceId);

      // assert
      expect(readState().status, RagChatbotStatus.error);
      expect(readState().error, 'Create failed');
    });

    test('should set loading before the call', () async {
      // arrange
      RagChatbotStatus? capturedStatus;
      when(() => mockRepo.createThread(
            workspaceId: any(named: 'workspaceId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async {
        capturedStatus = readState().status;
        return Right(tThread);
      });

      // act
      await readNotifier().startNewThread(workspaceId: tWorkspaceId);

      // assert
      expect(capturedStatus, RagChatbotStatus.loading);
    });
  });

  // --- createThreadIfNeeded ---

  group('createThreadIfNeeded', () {
    test('should return existing thread id if already active', () async {
      // arrange — set up active thread
      when(() => mockRepo.createThread(
            workspaceId: any(named: 'workspaceId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async => Right(tThread));
      await readNotifier().startNewThread(workspaceId: tWorkspaceId);
      expect(readState().activeThreadId, tThreadId);

      // act
      final result = await readNotifier().createThreadIfNeeded(
        workspaceId: tWorkspaceId,
      );

      // assert — should return existing, not call createThread again
      expect(result, tThreadId);
      verify(() => mockRepo.createThread(
            workspaceId: any(named: 'workspaceId'),
            title: any(named: 'title'),
          )).called(1); // only the initial call
    });

    test('should create new thread if none active', () async {
      // arrange
      when(() => mockRepo.createThread(
            workspaceId: any(named: 'workspaceId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async => Right(tThread));

      // act
      final result = await readNotifier().createThreadIfNeeded(
        workspaceId: tWorkspaceId,
        title: 'Custom title',
      );

      // assert
      expect(result, tThreadId);
      expect(readState().activeThreadId, tThreadId);
    });

    test('should return null on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Failed');
      when(() => mockRepo.createThread(
            workspaceId: any(named: 'workspaceId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await readNotifier().createThreadIfNeeded(
        workspaceId: tWorkspaceId,
      );

      // assert
      expect(result, isNull);
      expect(readState().status, RagChatbotStatus.error);
    });
  });

  // --- openThread ---

  group('openThread', () {
    test('should load thread and set state to ready on success', () async {
      // arrange
      when(() => mockRepo.getThread(threadId: any(named: 'threadId')))
          .thenAnswer((_) async => Right(tThreadWithMessages));
      when(() => mockRepo.syncPendingMessages(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => const Right(true));

      // act
      await readNotifier().openThread(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
        syncPendingAfterOpen: false,
      );

      // assert
      final state = readState();
      expect(state.status, RagChatbotStatus.ready);
      expect(state.activeThreadId, tThreadId);
      expect(state.messages.length, 2);
    });

    test('should set state to error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Thread not found');
      when(() => mockRepo.getThread(threadId: any(named: 'threadId')))
          .thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().openThread(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
        syncPendingAfterOpen: false,
      );

      // assert
      expect(readState().status, RagChatbotStatus.error);
      expect(readState().error, 'Thread not found');
    });

    test('should skip if thread already active and loaded', () async {
      // arrange — load thread first
      when(() => mockRepo.getThread(threadId: any(named: 'threadId')))
          .thenAnswer((_) async => Right(tThreadWithMessages));
      await readNotifier().openThread(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
        syncPendingAfterOpen: false,
      );
      expect(readState().status, RagChatbotStatus.ready);

      // act — open same thread again
      await readNotifier().openThread(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
        syncPendingAfterOpen: false,
      );

      // assert — getThread called only once
      verify(() => mockRepo.getThread(threadId: tThreadId)).called(1);
    });

    test('should sync pending messages when syncPendingAfterOpen is true',
        () async {
      // arrange
      when(() => mockRepo.getThread(threadId: any(named: 'threadId')))
          .thenAnswer((_) async => Right(tThreadWithMessages));
      when(() => mockRepo.syncPendingMessages(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => const Right(true));

      // act
      await readNotifier().openThread(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
        syncPendingAfterOpen: true,
      );

      // assert
      verify(() => mockRepo.syncPendingMessages(
            workspaceId: tWorkspaceId,
            threadId: tThreadId,
          )).called(1);
    });
  });

  // --- fetchThreads ---

  group('fetchThreads', () {
    test('should set threads on success', () async {
      // arrange
      when(() => mockRepo.listThreads(
            workspaceId: any(named: 'workspaceId'),
          )).thenAnswer((_) async => Right([tThread, tThread2]));

      // act
      await readNotifier().fetchThreads(workspaceId: tWorkspaceId);

      // assert
      final state = readState();
      expect(state.status, RagChatbotStatus.ready);
      expect(state.threads.length, 2);
      expect(state.activeWorkspaceId, tWorkspaceId);
    });

    test('should set error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'List failed');
      when(() => mockRepo.listThreads(
            workspaceId: any(named: 'workspaceId'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().fetchThreads(workspaceId: tWorkspaceId);

      // assert
      expect(readState().status, RagChatbotStatus.error);
      expect(readState().error, 'List failed');
    });

    test('should skip if threads already loaded for workspace', () async {
      // arrange — load threads first
      when(() => mockRepo.listThreads(
            workspaceId: any(named: 'workspaceId'),
          )).thenAnswer((_) async => Right([tThread]));
      await readNotifier().fetchThreads(workspaceId: tWorkspaceId);
      expect(readState().status, RagChatbotStatus.ready);
      expect(readState().threads.isNotEmpty, true);

      // act — same workspace
      await readNotifier().fetchThreads(workspaceId: tWorkspaceId);

      // assert — listThreads called twice (no longer skips for same workspace)
      verify(() => mockRepo.listThreads(workspaceId: tWorkspaceId)).called(2);
    });
  });

  // --- deleteThread ---

  group('deleteThread', () {
    test('should clear active thread if it was the deleted one', () async {
      // arrange — open a thread
      when(() => mockRepo.getThread(threadId: any(named: 'threadId')))
          .thenAnswer((_) async => Right(tThread));
      await readNotifier().openThread(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
        syncPendingAfterOpen: false,
      );
      expect(readState().activeThreadId, tThreadId);

      when(() => mockRepo.deleteThread(threadId: any(named: 'threadId')))
          .thenAnswer((_) async => const Right(true));
      when(() => mockRepo.listThreads(workspaceId: any(named: 'workspaceId')))
          .thenAnswer((_) async => const Right([]));

      // act
      await readNotifier().deleteThread(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
      );

      // assert
      expect(readState().activeThreadId, isNull);
      expect(readState().messages, isEmpty);
    });

    test('should set error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Delete failed');
      when(() => mockRepo.deleteThread(threadId: any(named: 'threadId')))
          .thenAnswer((_) async => const Left(failure));
      when(() => mockRepo.listThreads(workspaceId: any(named: 'workspaceId')))
          .thenAnswer((_) async => const Right([]));

      // act
      await readNotifier().deleteThread(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
      );

      // assert
      expect(readState().error, 'Delete failed');
    });

    test('should refetch threads after delete', () async {
      // arrange
      when(() => mockRepo.deleteThread(threadId: any(named: 'threadId')))
          .thenAnswer((_) async => const Right(true));
      when(() => mockRepo.listThreads(workspaceId: any(named: 'workspaceId')))
          .thenAnswer((_) async => Right([tThread2]));

      // act
      await readNotifier().deleteThread(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
      );

      // assert
      verify(() => mockRepo.listThreads(workspaceId: tWorkspaceId)).called(1);
    });
  });

  // --- deleteThreads ---

  group('deleteThreads', () {
    test('should delete multiple threads', () async {
      // arrange
      when(() => mockRepo.deleteThread(threadId: any(named: 'threadId')))
          .thenAnswer((_) async => const Right(true));
      when(() => mockRepo.listThreads(workspaceId: any(named: 'workspaceId')))
          .thenAnswer((_) async => const Right([]));

      // act
      await readNotifier().deleteThreads(
        workspaceId: tWorkspaceId,
        threadIds: [tThreadId, 'thread-2'],
      );

      // assert
      verify(() => mockRepo.deleteThread(threadId: tThreadId)).called(1);
      verify(() => mockRepo.deleteThread(threadId: 'thread-2')).called(1);
    });

    test('should clear active thread if among deleted', () async {
      // arrange — open a thread first
      when(() => mockRepo.getThread(threadId: any(named: 'threadId')))
          .thenAnswer((_) async => Right(tThread));
      await readNotifier().openThread(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
        syncPendingAfterOpen: false,
      );

      when(() => mockRepo.deleteThread(threadId: any(named: 'threadId')))
          .thenAnswer((_) async => const Right(true));
      when(() => mockRepo.listThreads(workspaceId: any(named: 'workspaceId')))
          .thenAnswer((_) async => const Right([]));

      // act
      await readNotifier().deleteThreads(
        workspaceId: tWorkspaceId,
        threadIds: [tThreadId],
      );

      // assert
      expect(readState().activeThreadId, isNull);
      expect(readState().messages, isEmpty);
    });
  });

  // --- updateThreadTitle ---

  group('updateThreadTitle', () {
    test('should call repo and refetch threads on success', () async {
      // arrange
      when(() => mockRepo.updateThreadTitle(
            threadId: any(named: 'threadId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async => const Right(true));
      when(() => mockRepo.listThreads(workspaceId: any(named: 'workspaceId')))
          .thenAnswer((_) async => Right([tThread]));

      // act
      await readNotifier().updateThreadTitle(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
        title: 'Renamed',
      );

      // assert
      verify(() => mockRepo.updateThreadTitle(
            threadId: tThreadId,
            title: 'Renamed',
          )).called(1);
      verify(() => mockRepo.listThreads(workspaceId: tWorkspaceId)).called(1);
    });

    test('should set error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Rename failed');
      when(() => mockRepo.updateThreadTitle(
            threadId: any(named: 'threadId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async => const Left(failure));
      when(() => mockRepo.listThreads(workspaceId: any(named: 'workspaceId')))
          .thenAnswer((_) async => const Right([]));

      // act
      await readNotifier().updateThreadTitle(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
        title: 'Renamed',
      );

      // assert
      expect(readState().error, 'Rename failed');
    });
  });

  // --- syncPendingMessages ---

  group('syncPendingMessages', () {
    test('should set chatStatus to syncing during call', () async {
      // arrange
      RagChatStatus? capturedStatus;
      when(() => mockRepo.syncPendingMessages(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async {
        capturedStatus = readState().chatStatus;
        return const Right(true);
      });
      when(() => mockRepo.getThread(threadId: any(named: 'threadId')))
          .thenAnswer((_) async => Right(tThread));

      // act
      await readNotifier().syncPendingMessages(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
      );

      // assert
      expect(capturedStatus, RagChatStatus.syncing);
    });

    test('should refresh thread after successful sync', () async {
      // arrange
      when(() => mockRepo.syncPendingMessages(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => const Right(true));
      when(() => mockRepo.getThread(threadId: any(named: 'threadId')))
          .thenAnswer((_) async => Right(tThreadWithMessages));

      // act
      await readNotifier().syncPendingMessages(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
      );

      // assert
      expect(readState().status, RagChatbotStatus.ready);
      expect(readState().activeThreadId, tThreadId);
      expect(readState().messages.length, 2);
      expect(readState().chatStatus, RagChatStatus.idle);
    });

    test('should set error on sync failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Sync failed');
      when(() => mockRepo.syncPendingMessages(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().syncPendingMessages(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
      );

      // assert
      expect(readState().status, RagChatbotStatus.error);
      expect(readState().error, 'Sync failed');
      expect(readState().chatStatus, RagChatStatus.idle);
    });

    test('should set error if getThread fails after sync', () async {
      // arrange
      when(() => mockRepo.syncPendingMessages(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => const Right(true));
      const failure = ApiFailure(message: 'Get thread failed');
      when(() => mockRepo.getThread(threadId: any(named: 'threadId')))
          .thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().syncPendingMessages(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
      );

      // assert
      expect(readState().status, RagChatbotStatus.error);
      expect(readState().error, 'Get thread failed');
    });
  });

  // --- sendMessageEnsureThread ---

  group('sendMessageEnsureThread', () {
    test('should add pending user message and call repo.chat', () async {
      // arrange — set up an active thread
      when(() => mockRepo.createThread(
            workspaceId: any(named: 'workspaceId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async => Right(tThread));
      await readNotifier().startNewThread(workspaceId: tWorkspaceId);

      final chatMessages = [
        const ChatMessageEntity(
          id: 'msg-1',
          threadId: tThreadId,
          role: 'user',
          content: 'Hello',
        ),
        const ChatMessageEntity(
          id: 'msg-2',
          threadId: tThreadId,
          role: 'assistant',
          content: 'Hi!',
        ),
      ];
      when(() => mockRepo.chat(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
            message: any(named: 'message'),
          )).thenAnswer((_) async => Right(chatMessages));

      // act
      await readNotifier().sendMessageEnsureThread(
        workspaceId: tWorkspaceId,
        message: 'Hello',
        threadId: tThreadId,
      );

      // assert
      final state = readState();
      expect(state.status, RagChatbotStatus.ready);
      expect(state.chatStatus, RagChatStatus.idle);
      expect(state.assistantTyping, false);
      verify(() => mockRepo.chat(
            workspaceId: tWorkspaceId,
            threadId: tThreadId,
            message: 'Hello',
          )).called(1);
    });

    test('should not send empty message', () async {
      // act
      await readNotifier().sendMessageEnsureThread(
        workspaceId: tWorkspaceId,
        message: '   ',
      );

      // assert
      verifyNever(() => mockRepo.chat(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
            message: any(named: 'message'),
          ));
    });

    test('should mark message as failed on error', () async {
      // arrange — set up active thread
      when(() => mockRepo.createThread(
            workspaceId: any(named: 'workspaceId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async => Right(tThread));
      await readNotifier().startNewThread(workspaceId: tWorkspaceId);

      const failure = ApiFailure(message: 'Chat error');
      when(() => mockRepo.chat(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
            message: any(named: 'message'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().sendMessageEnsureThread(
        workspaceId: tWorkspaceId,
        message: 'Hello',
        threadId: tThreadId,
      );

      // assert
      final state = readState();
      expect(state.status, RagChatbotStatus.error);
      expect(state.error, 'Chat error');
      expect(state.assistantTyping, false);
      // The local user message should be marked as failed
      final userMsgs = state.messages.where((m) => m.role == 'user');
      expect(userMsgs.isNotEmpty, true);
      expect(userMsgs.first.failed, true);
      expect(userMsgs.first.pending, false);
    });

    test('should create thread if no threadId provided', () async {
      // arrange
      when(() => mockRepo.createThread(
            workspaceId: any(named: 'workspaceId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async => Right(tThread));

      final chatMessages = [
        const ChatMessageEntity(
          id: 'msg-1',
          threadId: tThreadId,
          role: 'user',
          content: 'Hello',
        ),
      ];
      when(() => mockRepo.chat(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
            message: any(named: 'message'),
          )).thenAnswer((_) async => Right(chatMessages));

      // act
      await readNotifier().sendMessageEnsureThread(
        workspaceId: tWorkspaceId,
        message: 'Hello',
      );

      // assert — createThread should have been called
      verify(() => mockRepo.createThread(
            workspaceId: tWorkspaceId,
            title: 'New chat',
          )).called(1);
    });
  });

  // --- resendMessage ---

  group('resendMessage', () {
    test('should resend a failed message and update state', () async {
      // arrange — set up a thread with a failed message
      when(() => mockRepo.createThread(
            workspaceId: any(named: 'workspaceId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async => Right(tThread));
      await readNotifier().startNewThread(workspaceId: tWorkspaceId);

      // Simulate a failed send
      const failure = ApiFailure(message: 'Failed');
      when(() => mockRepo.chat(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
            message: any(named: 'message'),
          )).thenAnswer((_) async => const Left(failure));
      await readNotifier().sendMessageEnsureThread(
        workspaceId: tWorkspaceId,
        message: 'Hello',
        threadId: tThreadId,
      );

      final failedMsg = readState().messages.firstWhere((m) => m.failed);
      expect(failedMsg.failed, true);

      // Now set up successful retry
      final retryMessages = [
        ChatMessageEntity(
          id: failedMsg.id,
          threadId: tThreadId,
          role: 'user',
          content: 'Hello',
        ),
        const ChatMessageEntity(
          id: 'msg-reply',
          threadId: tThreadId,
          role: 'assistant',
          content: 'Response',
        ),
      ];
      when(() => mockRepo.chat(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
            message: any(named: 'message'),
          )).thenAnswer((_) async => Right(retryMessages));

      // act
      await readNotifier().resendMessage(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
        messageId: failedMsg.id,
      );

      // assert
      expect(readState().status, RagChatbotStatus.ready);
      expect(readState().chatStatus, RagChatStatus.idle);
    });

    test('should do nothing if message not found', () async {
      // act
      await readNotifier().resendMessage(
        workspaceId: tWorkspaceId,
        threadId: tThreadId,
        messageId: 'nonexistent',
      );

      // assert — no repo calls
      verifyNever(() => mockRepo.chat(
            workspaceId: any(named: 'workspaceId'),
            threadId: any(named: 'threadId'),
            message: any(named: 'message'),
          ));
    });
  });

  // --- selectWorkspace ---

  group('selectWorkspace (via fetchThreads)', () {
    test('should set activeWorkspaceId when fetching threads', () async {
      // arrange
      when(() => mockRepo.listThreads(
            workspaceId: any(named: 'workspaceId'),
          )).thenAnswer((_) async => Right([tThread]));

      // act
      await readNotifier().fetchThreads(workspaceId: 'ws-new');

      // assert
      expect(readState().activeWorkspaceId, 'ws-new');
    });
  });
}

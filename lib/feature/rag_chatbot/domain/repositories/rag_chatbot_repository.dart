import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/entities/chat_message_entity.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/entities/chat_thread_entity.dart';

abstract class IRagChatbotRepository {
  Future<Either<Failure, ChatThreadEntity>> createThread({
    required String workspaceId,
    String? title,
  });

  Future<Either<Failure, List<ChatThreadEntity>>> listThreads({
    required String workspaceId,
  });

  Future<Either<Failure, ChatThreadEntity>> getThread({
    required String threadId,
  });

  Future<Either<Failure, bool>> deleteThread({
    required String threadId,
  });

  /// Local-first chat:
  /// 1) write user msg locally
  /// 2) if online -> call API, cache returned messages
  /// 3) if offline -> queue pending msg
  Future<Either<Failure, List<ChatMessageEntity>>> chat({
    required String workspaceId,
    required String threadId,
    required String message,
  });

  /// Optional: flush queued messages for a thread (call when network returns)
  Future<Either<Failure, bool>> syncPendingMessages({
    required String workspaceId,
    required String threadId,
  });

  /// Update thread title (local-only, no server API yet)
  Future<Either<Failure, bool>> updateThreadTitle({
    required String threadId,
    required String title,
  });
}

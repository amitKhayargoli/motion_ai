import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';

import '../entities/chat_message_entity.dart';
import '../repositories/rag_chatbot_repository.dart';

class ChatParams {
  final String workspaceId;
  final String threadId;
  final String message;

  ChatParams({
    required this.workspaceId,
    required this.threadId,
    required this.message,
  });
}

class ChatUseCase {
  final IRagChatbotRepository repo;
  ChatUseCase(this.repo);

  Future<Either<Failure, List<ChatMessageEntity>>> call(ChatParams p) {
    return repo.chat(
      workspaceId: p.workspaceId,
      threadId: p.threadId,
      message: p.message,
    );
  }
}

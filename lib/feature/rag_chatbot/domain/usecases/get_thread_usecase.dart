import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';

import '../entities/chat_thread_entity.dart';
import '../repositories/rag_chatbot_repository.dart';

class GetThreadParams {
  final String threadId;
  GetThreadParams({required this.threadId});
}

class GetThreadUseCase {
  final IRagChatbotRepository repo;
  GetThreadUseCase(this.repo);

  Future<Either<Failure, ChatThreadEntity>> call(GetThreadParams p) {
    return repo.getThread(threadId: p.threadId);
  }
}

import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';

import '../entities/chat_thread_entity.dart';
import '../repositories/rag_chatbot_repository.dart';

class ListThreadsParams {
  final String workspaceId;
  ListThreadsParams({required this.workspaceId});
}

class ListThreadsUseCase {
  final IRagChatbotRepository repo;
  ListThreadsUseCase(this.repo);

  Future<Either<Failure, List<ChatThreadEntity>>> call(ListThreadsParams p) {
    return repo.listThreads(workspaceId: p.workspaceId);
  }
}

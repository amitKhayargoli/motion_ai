import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';

import '../repositories/rag_chatbot_repository.dart';

class SyncPendingParams {
  final String workspaceId;
  final String threadId;

  SyncPendingParams({required this.workspaceId, required this.threadId});
}

class SyncPendingMessagesUseCase {
  final IRagChatbotRepository repo;
  SyncPendingMessagesUseCase(this.repo);

  Future<Either<Failure, bool>> call(SyncPendingParams p) {
    return repo.syncPendingMessages(
      workspaceId: p.workspaceId,
      threadId: p.threadId,
    );
  }
}

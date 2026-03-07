import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';

import '../repositories/rag_chatbot_repository.dart';

class DeleteThreadParams {
  final String threadId;
  DeleteThreadParams({required this.threadId});
}

class DeleteThreadUseCase {
  final IRagChatbotRepository repo;
  DeleteThreadUseCase(this.repo);

  Future<Either<Failure, bool>> call(DeleteThreadParams p) {
    return repo.deleteThread(threadId: p.threadId);
  }
}

import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';

import '../entities/chat_thread_entity.dart';
import '../repositories/rag_chatbot_repository.dart';

class CreateThreadParams {
  final String workspaceId;
  final String? title;
  CreateThreadParams({required this.workspaceId, this.title});
}

class CreateThreadUseCase {
  final IRagChatbotRepository repo;
  CreateThreadUseCase(this.repo);

  Future<Either<Failure, ChatThreadEntity>> call(CreateThreadParams p) {
    return repo.createThread(workspaceId: p.workspaceId, title: p.title);
  }
}

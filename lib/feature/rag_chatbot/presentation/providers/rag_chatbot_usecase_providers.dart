// rag_chatbot_usecase_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/create_thread_usecase.dart';
import '../../domain/usecases/list_threads_usecase.dart';
import '../../domain/usecases/get_thread_usecase.dart';
import '../../domain/usecases/delete_thread_usecase.dart';
import '../../domain/usecases/chat_usecase.dart';
import '../../domain/usecases/sync_pending_messages_usecase.dart';
import 'rag_chatbot_providers.dart';

final createThreadUseCaseProvider = Provider((ref) {
  return CreateThreadUseCase(ref.read(ragChatbotRepositoryProvider));
});

final listThreadsUseCaseProvider = Provider((ref) {
  return ListThreadsUseCase(ref.read(ragChatbotRepositoryProvider));
});

final getThreadUseCaseProvider = Provider((ref) {
  return GetThreadUseCase(ref.read(ragChatbotRepositoryProvider));
});

final deleteThreadUseCaseProvider = Provider((ref) {
  return DeleteThreadUseCase(ref.read(ragChatbotRepositoryProvider));
});

final chatUseCaseProvider = Provider((ref) {
  return ChatUseCase(ref.read(ragChatbotRepositoryProvider));
});

final syncPendingMessagesUseCaseProvider = Provider((ref) {
  return SyncPendingMessagesUseCase(ref.read(ragChatbotRepositoryProvider));
});

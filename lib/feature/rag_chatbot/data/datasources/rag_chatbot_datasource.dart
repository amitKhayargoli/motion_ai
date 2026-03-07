// rag_chatbot_datasource.dart
// feature/rag/data/datasources/rag_chatbot_datasource.dart

import 'package:motion_ai/feature/rag_chatbot/data/models/chat_answer_api_model.dart';
import 'package:motion_ai/feature/rag_chatbot/data/models/chat_message_hive_model.dart';
import 'package:motion_ai/feature/rag_chatbot/data/models/chat_thread_api_model.dart';
import 'package:motion_ai/feature/rag_chatbot/data/models/chat_thread_hive_model.dart';

abstract class IRagChatbotRemoteDataSource {
  Future<ChatThreadApiModel> createThread({
    required String workspaceId,
    String? title,
  });

  Future<List<ChatThreadApiModel>> listThreads({
    required String workspaceId,
  });

  Future<ChatThreadApiModel> getThread({
    required String threadId,
  });

  Future<void> deleteThread({
    required String threadId,
  });

  Future<void> updateThreadTitle({
    required String threadId,
    required String title,
  });

  /// Sends a message and returns the updated messages (or at least the new assistant reply)
  Future<ChatAnswerApiModel> chat({
    required String workspaceId,
    required String threadId,
    required String question,
  });
}

abstract class IRagChatbotLocalDataSource {
  // Threads
  Future<void> upsertThread(ChatThreadHiveModel thread);
  Future<void> upsertThreads(List<ChatThreadHiveModel> threads);
  Future<List<ChatThreadHiveModel>> getThreadsByWorkspace(String workspaceId);
  Future<ChatThreadHiveModel?> getThreadById(String threadId);
  Future<void> deleteThread(String threadId);
  Future<void> clearThreadsByWorkspace(String workspaceId);

  // Messages
  Future<void> upsertMessages(String threadId, List<ChatMessageHiveModel> msgs);
  Future<List<ChatMessageHiveModel>> getMessages(String threadId);
  Future<void> clearMessages(String threadId);

  /// Optional: store a queued outgoing user message when offline (local-first)
  Future<void> enqueuePendingMessage({
    required String workspaceId,
    required String threadId,
    required ChatMessageHiveModel message,
  });

  Future<List<ChatMessageHiveModel>> getPendingMessages(String threadId);
  Future<void> clearPendingMessages(String threadId);

  // Pending title updates (offline queue)
  Future<void> enqueuePendingTitleUpdate({
    required String threadId,
    required String title,
  });
  Future<String?> getPendingTitleUpdate(String threadId);
  Future<Map<String, String>> getAllPendingTitleUpdates();
  Future<void> clearPendingTitleUpdate(String threadId);
}

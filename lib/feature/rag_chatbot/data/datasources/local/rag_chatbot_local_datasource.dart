import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:motion_ai/feature/rag_chatbot/data/datasources/rag_chatbot_datasource.dart';
import 'package:motion_ai/feature/rag_chatbot/data/models/chat_message_hive_model.dart';
import 'package:motion_ai/feature/rag_chatbot/data/models/chat_thread_hive_model.dart';

final ragChatbotLocalDatasourceProvider =
    Provider<IRagChatbotLocalDataSource>((ref) {
  return RagChatbotLocalDatasource();
});

class RagChatbotLocalDatasource implements IRagChatbotLocalDataSource {
  static const _threadsBox = "rag_threads";
  static const _messagesBox = "rag_thread_messages";
  static const _pendingBox = "rag_pending_messages";
  static const _pendingTitleBox = "rag_pending_title_updates";

  Future<Box> _openThreads() => Hive.openBox(_threadsBox);
  Future<Box> _openMessages() => Hive.openBox(_messagesBox);
  Future<Box> _openPending() => Hive.openBox(_pendingBox);
  Future<Box> _openPendingTitles() => Hive.openBox(_pendingTitleBox);

  // ================= THREADS =================

  @override
  Future<void> upsertThread(ChatThreadHiveModel thread) async {
    final box = await _openThreads();
    await box.put(thread.id, thread);
  }

  @override
  Future<void> upsertThreads(List<ChatThreadHiveModel> threads) async {
    final box = await _openThreads();
    final map = {for (final t in threads) t.id: t};
    await box.putAll(map);
  }

  @override
  Future<List<ChatThreadHiveModel>> getThreadsByWorkspace(
      String workspaceId) async {
    final box = await _openThreads();
    return box.values
        .whereType<ChatThreadHiveModel>()
        .where((t) => t.workspaceId == workspaceId)
        .toList();
  }

  @override
  Future<ChatThreadHiveModel?> getThreadById(String threadId) async {
    final box = await _openThreads();
    return box.get(threadId);
  }

  @override
  Future<void> deleteThread(String threadId) async {
    final threads = await _openThreads();
    final messages = await _openMessages();
    await threads.delete(threadId);
    await messages.delete(threadId);
  }

  @override
  Future<void> clearThreadsByWorkspace(String workspaceId) async {
    final box = await _openThreads();
    final keys = box.keys.where((k) {
      final t = box.get(k);
      return t is ChatThreadHiveModel && t.workspaceId == workspaceId;
    }).toList();
    await box.deleteAll(keys);
  }

  // ================= MESSAGES =================

  @override
  Future<void> upsertMessages(
      String threadId, List<ChatMessageHiveModel> msgs) async {
    final box = await _openMessages();
    final list = msgs.map((m) => m.toJson()).toList();
    await box.put(threadId, list);
  }

  @override
  Future<List<ChatMessageHiveModel>> getMessages(String threadId) async {
    final box = await _openMessages();
    final raw = box.get(threadId);

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) =>
              ChatMessageHiveModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    return [];
  }

  @override
  Future<void> clearMessages(String threadId) async {
    final box = await _openMessages();
    await box.delete(threadId);
  }

  // ================= OFFLINE QUEUE =================

  @override
  Future<void> enqueuePendingMessage({
    required String workspaceId,
    required String threadId,
    required ChatMessageHiveModel message,
  }) async {
    final box = await _openPending();
    final raw = box.get(threadId) ?? [];
    final list = List<Map<String, dynamic>>.from(raw);
    list.add(message.toJson());
    await box.put(threadId, list);
  }

  @override
  Future<List<ChatMessageHiveModel>> getPendingMessages(String threadId) async {
    final box = await _openPending();
    final raw = box.get(threadId);

    if (raw is List) {
      return raw
          .map((m) =>
              ChatMessageHiveModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    return [];
  }

  @override
  Future<void> clearPendingMessages(String threadId) async {
    final box = await _openPending();
    await box.delete(threadId);
  }

  // ================= PENDING TITLE UPDATES =================

  @override
  Future<void> enqueuePendingTitleUpdate({
    required String threadId,
    required String title,
  }) async {
    final box = await _openPendingTitles();
    await box.put(threadId, title);
  }

  @override
  Future<String?> getPendingTitleUpdate(String threadId) async {
    final box = await _openPendingTitles();
    return box.get(threadId) as String?;
  }

  @override
  Future<Map<String, String>> getAllPendingTitleUpdates() async {
    final box = await _openPendingTitles();
    final map = <String, String>{};
    for (final key in box.keys) {
      final val = box.get(key);
      if (val is String) map[key.toString()] = val;
    }
    return map;
  }

  @override
  Future<void> clearPendingTitleUpdate(String threadId) async {
    final box = await _openPendingTitles();
    await box.delete(threadId);
  }
}

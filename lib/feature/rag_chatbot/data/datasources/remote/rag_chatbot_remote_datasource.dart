import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/api/api_client.dart';
import 'package:motion_ai/core/api/api_endpoints.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/feature/rag_chatbot/data/datasources/rag_chatbot_datasource.dart';
import 'package:motion_ai/feature/rag_chatbot/data/models/chat_answer_api_model.dart';
import 'package:motion_ai/feature/rag_chatbot/data/models/chat_thread_api_model.dart';

final ragChatbotRemoteDatasourceProvider =
    Provider<IRagChatbotRemoteDataSource>((ref) {
  return RagChatbotRemoteDatasource(api: ref.read(apiClientProvider));
});

class RagChatbotRemoteDatasource implements IRagChatbotRemoteDataSource {
  final ApiClient _api;

  RagChatbotRemoteDatasource({required ApiClient api}) : _api = api;

  dynamic _extractData(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body['data'];
    }
    throw Exception("Invalid API response format");
  }

  // ================= CREATE THREAD =================
  @override
  Future<ChatThreadApiModel> createThread({
    required String workspaceId,
    String? title,
  }) async {
    final res = await _api.post(
      ApiEndpoints.createRagThread,
      data: {
        "workspaceId": workspaceId,
        if (title != null) "title": title,
      },
    );

    final data = _extractData(res.data);
    return ChatThreadApiModel.fromJson(Map<String, dynamic>.from(data));
  }

  // ================= LIST THREADS =================
  @override
  Future<List<ChatThreadApiModel>> listThreads({
    required String workspaceId,
  }) async {
    final res = await _api.get(
      ApiEndpoints.listRagThreads,
      queryParameters: {"workspaceId": workspaceId},
    );

    final data = _extractData(res.data);

    if (data is List) {
      return data
          .map((e) => ChatThreadApiModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return [];
  }

  // ================= GET THREAD =================
  @override
  Future<ChatThreadApiModel> getThread({
    required String threadId,
  }) async {
    final res = await _api.get(
      ApiEndpoints.getRagThreadById(threadId),
    );

    final data = _extractData(res.data);

    return ChatThreadApiModel.fromJson(Map<String, dynamic>.from(data));
  }

  // ================= DELETE THREAD =================
  @override
  Future<void> deleteThread({
    required String threadId,
  }) async {
    await _api.delete(ApiEndpoints.deleteRagThread(threadId));
  }

  // ================= UPDATE THREAD TITLE =================
  @override
  Future<void> updateThreadTitle({
    required String threadId,
    required String title,
  }) async {
    await _api.put(
      ApiEndpoints.updateRagThread(threadId),
      data: {"title": title},
    );
  }

  // ================= CHAT =================
  @override
  Future<ChatAnswerApiModel> chat({
    required String workspaceId,
    required String threadId,
    required String question,
  }) async {
    final res = await _api.post(
      ApiEndpoints.createRagchat,
      data: {
        "workspaceId": workspaceId,
        "threadId": threadId,
        "question": question,
      },
    );

    final body = res.data;

    if (body is Map && body["data"] != null) {
      return ChatAnswerApiModel.fromJson(
        Map<String, dynamic>.from(body["data"]),
      );
    }

    throw Exception("Invalid chat response");
  }
}

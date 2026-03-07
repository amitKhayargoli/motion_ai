import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/api/api_client.dart';
import 'package:motion_ai/core/api/api_endpoints.dart';
import 'package:motion_ai/core/providers/providers.dart';

import '../note_datasource.dart';
import '../../models/note_api_model.dart';

final noteRemoteDatasourceProvider = Provider<INoteRemoteDataSource>((ref) {
  return NoteRemoteDatasource(api: ref.read(apiClientProvider));
});

class NoteRemoteDatasource implements INoteRemoteDataSource {
  final ApiClient _api;

  NoteRemoteDatasource({required ApiClient api}) : _api = api;

  // Extract { success: true, data: ... }
  dynamic _extractData(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body['data'];
    }
    throw Exception("Invalid API response format");
  }

  // ================= CREATE NOTE =================
  @override
  Future<NoteApiModel> createNote({
    required String workspaceId,
    required String title,
    required String content,
  }) async {
    final res = await _api.post(
      ApiEndpoints.createNote,
      data: {"workspaceId": workspaceId, "title": title, "content": content},
    );

    final data = _extractData(res.data);
    return NoteApiModel.fromJson(data as Map<String, dynamic>);
  }

  // ================= GET WORKSPACE NOTES =================
  @override
  Future<List<NoteApiModel>> getWorkspaceNotes(String workspaceId) async {
    final res = await _api.get(ApiEndpoints.workspaceNotes(workspaceId));

    final data = _extractData(res.data);

    if (data is List) {
      return data
          .map((e) => NoteApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  // ================= UPDATE NOTE =================
  @override
  Future<NoteApiModel> updateNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    final res = await _api.put(
      ApiEndpoints.noteById(noteId),
      data: {"title": title, "content": content},
    );

    final data = _extractData(res.data);
    return NoteApiModel.fromJson(data as Map<String, dynamic>);
  }

  // ================= DELETE NOTE =================
  @override
  Future<void> deleteNote(String noteId) async {
    await _api.delete(ApiEndpoints.noteById(noteId));
  }

  @override
  Future<NoteApiModel?> getTranscriptByAudioFileId(String audioFileId) async {
    final res =
        await _api.get(ApiEndpoints.transcriptByAudioFileId(audioFileId));
    final data = res.data;

    // your backend returns { success:true, data: note|null } maybe
    final payload = data is Map ? data['data'] : null;
    if (payload == null) return null;
    return NoteApiModel.fromJson(Map<String, dynamic>.from(payload));
  }

  // ================= TRANSCRIBE AUDIO =================
  @override
  Future<NoteApiModel> transcribeAudio({
    required String audioFileId,
    required String workspaceId,
    String? noteTitle,
  }) async {
    final res = await _api.post(
      ApiEndpoints.transcribeAudio(audioFileId),
      data: {
        "workspaceId": workspaceId,
        if (noteTitle != null && noteTitle.isNotEmpty) "noteTitle": noteTitle,
      },
    );

    final data = _extractData(res.data);
    // backend returns { note: {...}, language: "..." }
    final noteJson = data is Map ? data['note'] : data;
    return NoteApiModel.fromJson(Map<String, dynamic>.from(noteJson));
  }
}

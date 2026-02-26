import '../models/note_api_model.dart';
import '../models/note_hive_model.dart';

abstract class INoteLocalDataSource {
  Future<void> upsertNotes(List<NoteHiveModel> notes);
  Future<void> upsertNote(NoteHiveModel note);
  Future<List<NoteHiveModel>> getWorkspaceNotes(String workspaceId);

  /// REQUIRED for local-first update
  Future<NoteHiveModel?> getNoteById(String noteId);

  /// REQUIRED for merging pending edits
  Future<List<NoteHiveModel>> getPendingWorkspaceNotes(String workspaceId);
  Future<void> deleteNote(String noteId);
  Future<void> clearWorkspaceNotes(String workspaceId);
}

abstract class INoteRemoteDataSource {
  Future<List<NoteApiModel>> getWorkspaceNotes(String workspaceId);
  Future<NoteApiModel> createNote({
    required String workspaceId,
    required String title,
    required String content,
  });
  Future<NoteApiModel> updateNote({
    required String noteId,
    required String title,
    required String content,
  });
  Future<void> deleteNote(String noteId);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/core/services/hive/hive_service.dart';
import 'package:motion_ai/feature/notes/data/datasources/note_datasource.dart';
import 'package:motion_ai/feature/notes/data/models/note_hive_model.dart';

final noteLocalDatasourceProvider = Provider<INoteLocalDataSource>((ref) {
  return NoteLocalDatasource(hive: ref.read(hiveServiceProvider));
});

class NoteLocalDatasource implements INoteLocalDataSource {
  final HiveService hive;
  NoteLocalDatasource({required this.hive});

  @override
  Future<void> upsertNotes(List<NoteHiveModel> notes) =>
      hive.upsertNotes(notes);

  @override
  Future<void> upsertNote(NoteHiveModel note) => hive.upsertNote(note);

  @override
  Future<List<NoteHiveModel>> getWorkspaceNotes(String workspaceId) =>
      hive.getWorkspaceNotes(workspaceId);

  @override
  Future<NoteHiveModel?> getNoteById(String noteId) => hive.getNoteById(noteId);

  @override
  Future<void> deleteNote(String noteId) => hive.deleteNote(noteId);

  @override
  Future<void> clearWorkspaceNotes(String workspaceId) =>
      hive.clearWorkspaceNotes(workspaceId);

  @override
  Future<List<NoteHiveModel>> getPendingWorkspaceNotes(String workspaceId) =>
      hive.getPendingNotesForWorkspace(workspaceId);

  @override
  Future<NoteHiveModel?> getTranscriptByAudioFileId(String audioFileId) =>
      hive.getTranscriptByAudioFileId(audioFileId);
}

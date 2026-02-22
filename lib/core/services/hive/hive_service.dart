import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:motion_ai/core/constants/hive_table_constant.dart';
import 'package:motion_ai/feature/auth/data/models/auth_hive_model.dart';
import 'package:motion_ai/feature/audio_file/data/models/audio_file_hive_model.dart';
import 'package:motion_ai/feature/notes/data/models/note_hive_model.dart';
import 'package:motion_ai/feature/workspace/data/models/workspace_hive_model.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  bool _initialized = false;

  // ================= INIT =================

  Future<void> init() async {
    if (_initialized) return;

    final directory = await getApplicationDocumentsDirectory();
    Hive.init(directory.path);

    _registerAdapters();
    await _openBoxes();

    _initialized = true;
    debugPrint("Hive initialized (Auth + Audio + Workspaces + Notes)");
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(HiveTableConstant.userTypeId)) {
      Hive.registerAdapter(AuthHiveModelAdapter());
    }

    if (!Hive.isAdapterRegistered(HiveTableConstant.audioFileTypeId)) {
      Hive.registerAdapter(AudioFileHiveModelAdapter());
    }

    if (!Hive.isAdapterRegistered(HiveTableConstant.workspaceTypeId)) {
      Hive.registerAdapter(WorkspaceHiveModelAdapter());
    }

    if (!Hive.isAdapterRegistered(HiveTableConstant.notesTypeId)) {
      Hive.registerAdapter(NoteHiveModelAdapter());
    }
  }

  Future<void> _openBoxes() async {
    if (!Hive.isBoxOpen(HiveTableConstant.userTable)) {
      await Hive.openBox<AuthHiveModel>(HiveTableConstant.userTable);
    }

    if (!Hive.isBoxOpen(HiveTableConstant.audioFileTable)) {
      await Hive.openBox<AudioFileHiveModel>(HiveTableConstant.audioFileTable);
    }

    if (!Hive.isBoxOpen(HiveTableConstant.workspaceTable)) {
      await Hive.openBox<WorkspaceHiveModel>(HiveTableConstant.workspaceTable);
    }

    if (!Hive.isBoxOpen(HiveTableConstant.notesTable)) {
      await Hive.openBox<NoteHiveModel>(HiveTableConstant.notesTable);
    }
  }

  // ================= BOX GETTERS =================

  Box<AuthHiveModel> get _authBox {
    if (!Hive.isBoxOpen(HiveTableConstant.userTable)) {
      throw Exception(
        "Hive Box ${HiveTableConstant.userTable} is not open. Did you call init()?",
      );
    }
    return Hive.box<AuthHiveModel>(HiveTableConstant.userTable);
  }

  Box<AudioFileHiveModel> get _audioBox {
    if (!Hive.isBoxOpen(HiveTableConstant.audioFileTable)) {
      throw Exception(
        "Hive Box ${HiveTableConstant.audioFileTable} is not open. Did you call init()?",
      );
    }
    return Hive.box<AudioFileHiveModel>(HiveTableConstant.audioFileTable);
  }

  Box<WorkspaceHiveModel> get _workspaceBox {
    if (!Hive.isBoxOpen(HiveTableConstant.workspaceTable)) {
      throw Exception(
        "Hive Box ${HiveTableConstant.workspaceTable} is not open. Did you call init()?",
      );
    }
    return Hive.box<WorkspaceHiveModel>(HiveTableConstant.workspaceTable);
  }

  Box<NoteHiveModel> get _notesBox {
    if (!Hive.isBoxOpen(HiveTableConstant.notesTable)) {
      throw Exception(
        "Hive Box ${HiveTableConstant.notesTable} is not open. Did you call init()?",
      );
    }
    return Hive.box<NoteHiveModel>(HiveTableConstant.notesTable);
  }

  // ================= HELPERS =================

  String _emailKey(String email) => email.trim().toLowerCase();

  // ================= USER CRUD =================

  Future<AuthHiveModel> registerUser(AuthHiveModel user) async {
    final key = _emailKey(user.email);

    if (_authBox.containsKey(key)) {
      throw Exception("Email already registered");
    }

    await _authBox.put(key, user);
    return user;
  }

  Future<AuthHiveModel?> loginUser(String email, String password) async {
    final key = _emailKey(email);
    final user = _authBox.get(key);
    if (user == null) return null;

    if ((user.password ?? '') != password) return null;
    return user;
  }

  Future<AuthHiveModel?> getUserByEmail(String email) async {
    return _authBox.get(_emailKey(email));
  }

  Future<AuthHiveModel?> getUserById(String authId) async {
    try {
      return _authBox.values.firstWhere((u) => u.userId == authId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateUser(AuthHiveModel user) async {
    try {
      final key = _emailKey(user.email);
      await _authBox.put(key, user);
      return true;
    } catch (e) {
      debugPrint("Hive updateUser error: $e");
      return false;
    }
  }

  Future<void> deleteUserByEmail(String email) async {
    await _authBox.delete(_emailKey(email));
  }

  Future<void> deleteUser(String authId) async {
    final user = await getUserById(authId);
    if (user == null) return;
    await _authBox.delete(_emailKey(user.email));
  }

  Future<bool> isEmailExists(String email) async {
    return _authBox.containsKey(_emailKey(email));
  }

  // ================= AUDIO CRUD =================

  Future<void> saveAudio(AudioFileHiveModel audio) async {
    await _audioBox.put(audio.id, audio);
  }

  AudioFileHiveModel? getAudioById(String id) => _audioBox.get(id);

  List<AudioFileHiveModel> getAudiosByUploader(String uploaderId) {
    return _audioBox.values.where((a) => a.uploaderId == uploaderId).toList();
  }

  Future<List<AudioFileHiveModel>> getStoredAudios() async {
    return _audioBox.values.toList();
  }

  Future<void> deleteAudio(String id) async => _audioBox.delete(id);

  Future<void> clearAudioFiles() async => _audioBox.clear();

  // ================= WORKSPACE (CACHE) =================

  Future<void> upsertWorkspace(WorkspaceHiveModel ws) async {
    await _workspaceBox.put(ws.id, ws);
  }

  Future<void> upsertWorkspaces(List<WorkspaceHiveModel> list) async {
    final map = {for (final w in list) w.id: w};
    await _workspaceBox.putAll(map);
  }

  Future<List<WorkspaceHiveModel>> getAllWorkspaces() async {
    return _workspaceBox.values.toList();
  }

  Future<void> deleteWorkspace(String id) async {
    await _workspaceBox.delete(id);
  }

  Future<void> clearWorkspaces() async {
    await _workspaceBox.clear();
  }

  // ================= NOTES (CACHE) =================

  /// Upsert one note (local-first)
  Future<void> upsertNote(NoteHiveModel note) async {
    await _notesBox.put(note.id, note);
  }

  /// Upsert many notes (refresh cache)
  Future<void> upsertNotes(List<NoteHiveModel> notes) async {
    final map = {for (final n in notes) n.id: n};
    await _notesBox.putAll(map);
  }

  Future<NoteHiveModel?> getNoteById(String noteId) async {
    return _notesBox.get(noteId);
  }

  /// Get notes for a workspace
  Future<List<NoteHiveModel>> getWorkspaceNotes(String workspaceId) async {
    return _notesBox.values.where((n) => n.workspaceId == workspaceId).toList();
  }

  /// Delete note locally
  Future<void> deleteNote(String noteId) async {
    await _notesBox.delete(noteId);
  }

  /// Clear a workspace notes cache
  Future<void> clearWorkspaceNotes(String workspaceId) async {
    final keysToDelete = _notesBox.keys.where((k) {
      final n = _notesBox.get(k);
      return n?.workspaceId == workspaceId;
    }).toList();

    await _notesBox.deleteAll(keysToDelete);
  }

  // Future<List<NoteHiveModel>> getPendingNotes() async {
  //   // assumes your NoteHiveModel has int syncStatus field (0=synced)
  //   return _notesBox.values.where((n) => (n.syncStatus ?? 0) != 0).toList();
  // }

  Future<List<NoteHiveModel>> getPendingNotes() async {
    return _notesBox.values.where((n) => n.syncStatus != 0).toList();
  }

  Future<List<NoteHiveModel>> getPendingNotesForWorkspace(
      String workspaceId) async {
    return _notesBox.values
        .where((n) => n.workspaceId == workspaceId && n.syncStatus != 0)
        .toList();
  }

  // ================= CLOSE =================

  Future<void> close() async {
    await Hive.close();
    _initialized = false;
  }
}

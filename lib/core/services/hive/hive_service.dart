import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:motion_ai/core/constants/hive_table_constant.dart';
import 'package:motion_ai/feature/auth/data/models/auth_hive_model.dart';
import 'package:motion_ai/feature/audio_file/data/models/audio_file_hive_model.dart';
import 'package:motion_ai/feature/notes/data/models/note_hive_model.dart';
import 'package:motion_ai/feature/tasks/data/models/task_hive_model.dart';
import 'package:motion_ai/feature/rag_chatbot/data/models/chat_message_hive_model.dart';
import 'package:motion_ai/feature/rag_chatbot/data/models/chat_thread_hive_model.dart';
import 'package:motion_ai/feature/workspace/data/models/workspace_hive_model.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  bool _initialized = false;

  String? _activeUserId;

  // ================= INIT =================

  Future<void> init() async {
    if (_initialized) return;

    final directory = await getApplicationDocumentsDirectory();
    Hive.init(directory.path);

    _registerAdapters();
    await _openGlobalBoxes();

    _initialized = true;
    debugPrint("Hive initialized (global boxes ready)");
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
    if (!Hive.isAdapterRegistered(HiveTableConstant.taskTypeId)) {
      Hive.registerAdapter(TaskHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTableConstant.chatMessageTypeId)) {
      Hive.registerAdapter(ChatMessageHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTableConstant.chatThreadTypeId)) {
      Hive.registerAdapter(ChatThreadHiveModelAdapter());
    }
  }

  Future<void> _openGlobalBoxes() async {
    await Future.wait([
      if (!Hive.isBoxOpen(HiveTableConstant.userTable))
        Hive.openBox<AuthHiveModel>(HiveTableConstant.userTable),
      if (!Hive.isBoxOpen(HiveTableConstant.audioFileTable))
        Hive.openBox<AudioFileHiveModel>(HiveTableConstant.audioFileTable),
      if (!Hive.isBoxOpen(HiveTableConstant.workspaceTable))
        Hive.openBox<WorkspaceHiveModel>(HiveTableConstant.workspaceTable),
    ]);
  }

  // ================= USER SCOPING =================

  /// Call this right after login (and on app start if token exists)
  Future<void> setActiveUser(String userId) async {
    _activeUserId = userId;
    await _openUserBoxes(userId);
    debugPrint("Hive active user set: $userId");
  }

  /// Call this on logout (optional but recommended)
  Future<void> clearActiveUser() async {
    _activeUserId = null;
  }

  String get _u {
    final id = _activeUserId;
    if (id == null || id.isEmpty) {
      throw Exception(
          "HiveService: active user not set. Call setActiveUser(userId) after login.");
    }
    return id;
  }

  String _userNotesBoxName(String userId) =>
      "${HiveTableConstant.notesTable}_$userId";
  String _userTasksBoxName(String userId) =>
      "${HiveTableConstant.taskTable}_$userId";
  String _userChatThreadsBoxName(String userId) =>
      "${HiveTableConstant.chatThreadTable}_$userId";
  String _userChatMessagesBoxName(String userId) =>
      "${HiveTableConstant.chatMessageTable}_$userId";

  Future<void> _openUserBoxes(String userId) async {
    final notesBox = _userNotesBoxName(userId);
    final tasksBox = _userTasksBoxName(userId);
    final threadsBox = _userChatThreadsBoxName(userId);
    final messagesBox = _userChatMessagesBoxName(userId);

    await Future.wait([
      if (!Hive.isBoxOpen(notesBox)) Hive.openBox<NoteHiveModel>(notesBox),
      if (!Hive.isBoxOpen(tasksBox)) Hive.openBox<TaskHiveModel>(tasksBox),
      if (!Hive.isBoxOpen(threadsBox))
        Hive.openBox<ChatThreadHiveModel>(threadsBox),
      if (!Hive.isBoxOpen(messagesBox))
        Hive.openBox<ChatMessageHiveModel>(messagesBox),
    ]);
  }

  // ================= GLOBAL BOX GETTERS =================

  Box<AuthHiveModel> get _authBox {
    if (!Hive.isBoxOpen(HiveTableConstant.userTable)) {
      throw Exception(
          "Hive Box ${HiveTableConstant.userTable} is not open. Did you call init()?");
    }
    return Hive.box<AuthHiveModel>(HiveTableConstant.userTable);
  }

  Box<AudioFileHiveModel> get _audioBox {
    if (!Hive.isBoxOpen(HiveTableConstant.audioFileTable)) {
      throw Exception(
          "Hive Box ${HiveTableConstant.audioFileTable} is not open. Did you call init()?");
    }
    return Hive.box<AudioFileHiveModel>(HiveTableConstant.audioFileTable);
  }

  Box<WorkspaceHiveModel> get _workspaceBox {
    if (!Hive.isBoxOpen(HiveTableConstant.workspaceTable)) {
      throw Exception(
          "Hive Box ${HiveTableConstant.workspaceTable} is not open. Did you call init()?");
    }
    return Hive.box<WorkspaceHiveModel>(HiveTableConstant.workspaceTable);
  }

  // ================= USER-SCOPED BOX GETTERS =================

  Box<NoteHiveModel> get _notesBox {
    final name = _userNotesBoxName(_u);
    if (!Hive.isBoxOpen(name)) {
      throw Exception(
          "Hive Box $name is not open. Did you call setActiveUser(userId)?");
    }
    return Hive.box<NoteHiveModel>(name);
  }

  Box<TaskHiveModel> get _tasksBox {
    final name = _userTasksBoxName(_u);
    if (!Hive.isBoxOpen(name)) {
      throw Exception(
          "Hive Box $name is not open. Did you call setActiveUser(userId)?");
    }
    return Hive.box<TaskHiveModel>(name);
  }

  Box<ChatThreadHiveModel> get _chatThreadsBox {
    final name = _userChatThreadsBoxName(_u);
    if (!Hive.isBoxOpen(name)) {
      throw Exception(
          "Hive Box $name is not open. Did you call setActiveUser(userId)?");
    }
    return Hive.box<ChatThreadHiveModel>(name);
  }

  Box<ChatMessageHiveModel> get _chatMessagesBox {
    final name = _userChatMessagesBoxName(_u);
    if (!Hive.isBoxOpen(name)) {
      throw Exception(
          "Hive Box $name is not open. Did you call setActiveUser(userId)?");
    }
    return Hive.box<ChatMessageHiveModel>(name);
  }

  // ================= HELPERS =================

  String _emailKey(String email) => email.trim().toLowerCase();

  // ================= USER CRUD =================

  Future<AuthHiveModel> registerUser(AuthHiveModel user) async {
    final key = _emailKey(user.email);
    if (_authBox.containsKey(key)) throw Exception("Email already registered");
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

  Future<AuthHiveModel?> getUserByEmail(String email) async =>
      _authBox.get(_emailKey(email));

  Future<AuthHiveModel?> getUserById(String authId) async {
    try {
      return _authBox.values.firstWhere((u) => u.userId == authId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateUser(AuthHiveModel user) async {
    try {
      await _authBox.put(_emailKey(user.email), user);
      return true;
    } catch (e) {
      debugPrint("Hive updateUser error: $e");
      return false;
    }
  }

  Future<void> deleteUserByEmail(String email) async =>
      _authBox.delete(_emailKey(email));

  Future<void> deleteUser(String authId) async {
    final user = await getUserById(authId);
    if (user == null) return;
    await _authBox.delete(_emailKey(user.email));
  }

  Future<bool> isEmailExists(String email) async =>
      _authBox.containsKey(_emailKey(email));

  // ================= AUDIO CRUD =================

  Future<void> saveAudio(AudioFileHiveModel audio) async =>
      _audioBox.put(audio.id, audio);

  AudioFileHiveModel? getAudioById(String id) => _audioBox.get(id);

  List<AudioFileHiveModel> getAudiosByUploader(String uploaderId) =>
      _audioBox.values.where((a) => a.uploaderId == uploaderId).toList();

  Future<List<AudioFileHiveModel>> getStoredAudios() async =>
      _audioBox.values.toList();

  Future<void> deleteAudio(String id) async => _audioBox.delete(id);

  Future<void> clearAudioFiles() async => _audioBox.clear();

  Future<List<AudioFileHiveModel>> getPendingAudios() async =>
      _audioBox.values.where((a) => a.syncStatus != 0).toList();

  // ================= WORKSPACE (GLOBAL CACHE) =================

  Future<void> upsertWorkspace(WorkspaceHiveModel ws) async =>
      _workspaceBox.put(ws.id, ws);

  Future<void> upsertWorkspaces(List<WorkspaceHiveModel> list) async {
    final map = {for (final w in list) w.id: w};
    await _workspaceBox.putAll(map);
  }

  Future<List<WorkspaceHiveModel>> getAllWorkspaces() async =>
      _workspaceBox.values.toList();

  Future<void> deleteWorkspace(String id) async => _workspaceBox.delete(id);

  Future<void> clearWorkspaces() async => _workspaceBox.clear();

  // ================= NOTES (USER-SCOPED CACHE) =================

  Future<void> upsertNote(NoteHiveModel note) async {
    await _notesBox.put(note.id, note);
  }

  Future<void> upsertNotes(List<NoteHiveModel> notes) async {
    final map = {for (final n in notes) n.id: n};
    await _notesBox.putAll(map);
  }

  Future<NoteHiveModel?> getNoteById(String noteId) async =>
      _notesBox.get(noteId);

  Future<List<NoteHiveModel>> getWorkspaceNotes(String workspaceId) async {
    return _notesBox.values.where((n) => n.workspaceId == workspaceId).toList();
  }

  Future<void> deleteNote(String noteId) async => _notesBox.delete(noteId);

  Future<void> clearWorkspaceNotes(String workspaceId) async {
    final keysToDelete = _notesBox.keys.where((k) {
      final n = _notesBox.get(k);
      return n?.workspaceId == workspaceId;
    }).toList();
    await _notesBox.deleteAll(keysToDelete);
  }

  Future<List<NoteHiveModel>> getPendingNotes() async {
    return _notesBox.values.where((n) => n.syncStatus != 0).toList();
  }

  Future<List<NoteHiveModel>> getPendingNotesForWorkspace(
      String workspaceId) async {
    return _notesBox.values
        .where((n) => n.workspaceId == workspaceId && n.syncStatus != 0)
        .toList();
  }

  Future<NoteHiveModel?> getTranscriptByAudioFileId(String audioFileId) async {
    try {
      final candidates = _notesBox.values.where((n) =>
          n.audioFileId == audioFileId &&
          (n.type == null || n.type == "VOICE_TRANSCRIPT"));
      if (candidates.isEmpty) return null;

      final list = candidates.toList()
        ..sort((a, b) {
          final ad = a.updatedAt ?? a.createdAt ?? DateTime(0);
          final bd = b.updatedAt ?? b.createdAt ?? DateTime(0);
          return bd.compareTo(ad);
        });
      return list.first;
    } catch (_) {
      return null;
    }
  }

  // ================= TASKS (USER-SCOPED CACHE) =================

  Future<void> upsertTask(TaskHiveModel task) async {
    await _tasksBox.put(task.id, task);
  }

  Future<void> upsertTasks(List<TaskHiveModel> tasks) async {
    final map = {for (final t in tasks) t.id: t};
    await _tasksBox.putAll(map);
  }

  Future<TaskHiveModel?> getTaskById(String taskId) async =>
      _tasksBox.get(taskId);

  Future<List<TaskHiveModel>> getWorkspaceTasks(String workspaceId) async {
    return _tasksBox.values.where((t) => t.workspaceId == workspaceId).toList();
  }

  Future<void> deleteTask(String taskId) async => _tasksBox.delete(taskId);

  Future<void> clearWorkspaceTasks(String workspaceId) async {
    final keysToDelete = _tasksBox.keys.where((k) {
      final t = _tasksBox.get(k);
      return t?.workspaceId == workspaceId;
    }).toList();
    await _tasksBox.deleteAll(keysToDelete);
  }

  Future<List<TaskHiveModel>> getPendingTasksForWorkspace(
      String workspaceId) async {
    return _tasksBox.values
        .where((t) => t.workspaceId == workspaceId && t.syncStatus != 0)
        .toList();
  }

  // ================= RAG CHAT (USER-SCOPED CACHE) =================
  // (Optional: implement if you want offline threads/messages)

  Future<void> upsertChatThreads(List<ChatThreadHiveModel> threads) async {
    final map = {for (final t in threads) t.id: t};
    await _chatThreadsBox.putAll(map);
  }

  Future<List<ChatThreadHiveModel>> getChatThreadsByWorkspace(
      String workspaceId) async {
    return _chatThreadsBox.values
        .where((t) => t.workspaceId == workspaceId)
        .toList();
  }

  Future<void> upsertChatMessages(List<ChatMessageHiveModel> messages) async {
    // Key by message.id
    final map = {for (final m in messages) m.id: m};
    await _chatMessagesBox.putAll(map);
  }

  Future<List<ChatMessageHiveModel>> getChatMessagesByThread(
      String threadId) async {
    return _chatMessagesBox.values
        .where((m) => m.threadId == threadId)
        .toList();
  }

  Future<void> clearChatForWorkspace(String workspaceId) async {
    // 1) find all threads for this workspace
    final threadIds = _chatThreadsBox.values
        .where((t) => t.workspaceId == workspaceId)
        .map((t) => t.id)
        .toSet();

    // delete threads
    final threadKeys = _chatThreadsBox.keys.where((k) {
      final t = _chatThreadsBox.get(k);
      return t?.workspaceId == workspaceId;
    }).toList();
    await _chatThreadsBox.deleteAll(threadKeys);

    // 2) delete messages by threadId (no workspaceId needed)
    final msgKeys = _chatMessagesBox.keys.where((k) {
      final m = _chatMessagesBox.get(k);
      return m != null && threadIds.contains(m.threadId);
    }).toList();
    await _chatMessagesBox.deleteAll(msgKeys);
  }
  // ================= DEBUG =================

  void debugPrintNotesForWorkspace(String workspaceId) {
    final list =
        _notesBox.values.where((n) => n.workspaceId == workspaceId).toList();
    debugPrint(
        "HIVE(user=$_activeUserId) notes ws=$workspaceId count=${list.length}");
    for (final n in list) {
      debugPrint(" - id=${n.id} title=${n.title} sync=${n.syncStatus}");
    }
  }

  // ================= CLOSE =================

  Future<void> close() async {
    await Hive.close();
    _initialized = false;
    _activeUserId = null;
  }
}

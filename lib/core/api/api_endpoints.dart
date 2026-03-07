import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // ================= BASE URL =================

  static const bool _useAdbReverse =
      bool.fromEnvironment('USE_ADB_REVERSE', defaultValue: true);

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';

    if (Platform.isAndroid) {
      return _useAdbReverse
          ? 'http://127.0.0.1:3000/api' // physical device + adb reverse
          : 'http://10.0.2.2:3000/api'; // emulator (default)
    }

    // iOS simulator & macOS both resolve localhost to the host machine
    return 'http://localhost:3000/api';
  }

  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // ============ Auth Endpoints ============
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String getAllUsers = '/auth/users';
  static const String getMe = '/auth/me';
  static const String updateProfile = '/auth/user/update';

  // ============ AudioFile Endpoints ============
  static const String uploadAudio = '/audio/upload';
  static const String myAudioFiles = '/audio/my-files';
  static String getAudioById(String id) => '/audio/$id';
  static String updateAudio(String id) => '/audio/$id'; // PATCH
  static String deleteAudio(String id) => '/audio/$id'; // DELETE

  // ============ Workspace Endpoints ============
  static const String createWorkspace = '/workspaces'; // POST
  static const String myWorkspaces = '/workspaces'; // GET

  static const String joinWorkspace = '/workspace/join';

  static String workspaceById(String id) => '/workspaces/$id';
  static String updateWorkspace(String id) => '/workspace/$id';
  static String deleteWorkspace(String id) => '/workspace/$id';

  // ============ Notes Endpoints ============
  static const String createNote = '/notes'; // POST
  static String noteById(String id) => '/notes/$id'; // GET/PUT/DELETE

  static String workspaceNotes(String workspaceId) =>
      '/workspaces/$workspaceId/notes';

  static String transcriptByAudioFileId(String id) => '/notes/$id/transcript';

  static String transcribeAudio(String id) => '/audio/$id/transcribe';

  // ============ Tasks Endpoints ============
  static const String createTask = '/tasks'; // POST
  static String taskById(String id) => '/tasks/$id'; // GET/PUT/DELETE

  static String workspaceTasks(String workspaceId) =>
      '/workspaces/$workspaceId/tasks';

  // ============ RAG Endpoints ============
  static const String createRagThread = "/rag/thread"; // POST
  static const String listRagThreads = "/rag/thread"; // GET
  static String getRagThreadById(String id) => "/rag/thread/$id"; // GET
  static String deleteRagThread(String id) => "/rag/thread/$id"; // DELETE
  static String updateRagThread(String id) => "/rag/thread/$id"; // PUT
  static const String createRagchat = "/rag/chat"; // POST
}

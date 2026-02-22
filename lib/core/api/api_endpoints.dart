import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // ================= BASE URL =================
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    if (Platform.isAndroid) {
      // Android Emulator
      return 'http://10.0.2.2:3000/api';
    } else if (Platform.isIOS) {
      // iOS Simulator
      return 'http://localhost:3000/api';
    } else {
      // Physical device (change to your PC IP)
      return 'http://192.168.1.5:3000/api';
    }
  }

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ============ Auth Endpoints ============
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String getAllUsers = '/auth/users';
  static const String updateProfile = '/auth/user/update';

  // ============ AudioFile Endpoints ============
  static const String uploadAudio = '/audio/upload';
  static const String myAudioFiles = '/audio/my-files';
  static String getAudioById(String id) => '/audio/$id';
  static String deleteAudio(String id) => '/audio/$id';

  // ============ Workspace Endpoints ============
  static const String createWorkspace = '/workspaces'; // POST
  static const String myWorkspaces = '/workspaces'; // GET

  static const String joinWorkspace = '/workspace/join';

  static String workspaceById(String id) => '/workspaces/$id';
  static String deleteWorkspace(String id) => '/workspaces/$id';

  // ============ Notes Endpoints ============
  static const String createNote = '/notes'; // POST
  static String noteById(String id) => '/notes/$id'; // GET/PUT/DELETE

  static String workspaceNotes(String workspaceId) =>
      '/workspaces/$workspaceId/notes';
}

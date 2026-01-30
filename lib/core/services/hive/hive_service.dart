import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:motion_ai/core/constants/hive_table_constant.dart';
import 'package:motion_ai/feature/auth/data/models/auth_hive_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:motion_ai/feature/audio_file/data/models/audio_file_hive_model.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

class HiveService {
  static const String currentUserKey = "currentUser";

  /// Initialize Hive and Register Adapters
  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    Hive.init(directory.path);

    _registerAdapters();
    await _openBoxes();
  }

  void _registerAdapters() {
    // Register Auth adapter
    if (!Hive.isAdapterRegistered(HiveTableConstant.userTypeId)) {
      Hive.registerAdapter(AuthHiveModelAdapter());
    }

    if (!Hive.isAdapterRegistered(HiveTableConstant.audioFileTypeId)) {
      Hive.registerAdapter(AudioFileHiveModelAdapter());
    }
  }

  Future<void> _openBoxes() async {
    // Open auth box
    await Hive.openBox<AuthHiveModel>(HiveTableConstant.userTable);

    await Hive.openBox<AudioFileHiveModel>(HiveTableConstant.audioFileTable);
  }

  Box<AuthHiveModel> get _authBox {
    if (!Hive.isBoxOpen(HiveTableConstant.userTable)) {
      throw Exception(
        "Hive Box ${HiveTableConstant.userTable} is not open. Did you call init()?",
      );
    }
    return Hive.box<AuthHiveModel>(HiveTableConstant.userTable);
  }

  // ================= User CRUD Operations ====================

  /// Register a new user
  Future<AuthHiveModel> registerUser(AuthHiveModel user) async {
    // We use userId as the unique key in the Hive box
    await _authBox.put(user.userId, user);
    return user;
  }

  /// Login user by searching through all stored values
  Future<AuthHiveModel?> loginUser(String email, String password) async {
    try {
      return _authBox.values.firstWhere(
        (user) => user.email == email && user.password == password,
      );
    } catch (e) {
      return null; // Return null if user not found
    }
  }

  /// Logout - Clears the current session data
  Future<bool> logout() async {
    try {
      await _authBox.clear();
      await _audioBox.clear();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get user by ID (using the box key)
  Future<AuthHiveModel?> getUserById(String authId) async {
    return _authBox.get(authId);
  }

  /// Get user by email (filtering values)
  Future<AuthHiveModel?> getUserByEmail(String email) async {
    for (final user in _authBox.values) {
      if (user.email.trim().toLowerCase() == email.trim().toLowerCase()) {
        return user;
      }
    }
    return null;
  }

  /// Get current user
  Future<AuthHiveModel?> getCurrentUser() async {
    return _authBox.get(currentUserKey);
  }

  /// Update an existing user
  Future<bool> updateUser(AuthHiveModel user) async {
    if (_authBox.containsKey(user.userId)) {
      await _authBox.put(user.userId, user);
      return true;
    }
    return false;
  }

  /// Delete a user
  Future<void> deleteUser(String authId) async {
    await _authBox.delete(authId);
  }

  /// Check if email already exists
  Future<bool> isEmailExists(String email) async {
    return _authBox.values.any((user) => user.email == email);
  }

  Box<AudioFileHiveModel> get _audioBox {
    if (!Hive.isBoxOpen(HiveTableConstant.audioFileTable)) {
      throw Exception(
        "Hive Box ${HiveTableConstant.audioFileTable} is not open. Did you call init()?",
      );
    }
    return Hive.box<AudioFileHiveModel>(HiveTableConstant.audioFileTable);
  }

  // ================= AudioFile CRUD Operations ====================

  /// Save / cache audio file
  Future<void> saveAudio(AudioFileHiveModel audio) async {
    await _audioBox.put(audio.id, audio);
  }

  /// Get audio by ID
  AudioFileHiveModel? getAudioById(String id) {
    return _audioBox.get(id);
  }

  /// Get all audios uploaded by a user
  List<AudioFileHiveModel> getAudiosByUploader(String uploaderId) {
    return _audioBox.values
        .where((audio) => audio.uploaderId == uploaderId)
        .toList();
  }

  /// Get all stored audios
  Future<List<AudioFileHiveModel>> getStoredAudios() async {
    return _audioBox.values.toList();
  }

  /// Delete audio by ID
  Future<void> deleteAudio(String id) async {
    await _audioBox.delete(id);
  }

  /// Clear all audio files (e.g. on logout)
  Future<void> clearAudioFiles() async {
    await _audioBox.clear();
  }

  /// Close all boxes on app disposal
  Future<void> close() async {
    await Hive.close();
  }
}

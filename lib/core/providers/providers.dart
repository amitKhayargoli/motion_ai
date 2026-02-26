// lib/core/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:motion_ai/core/api/api_client.dart';
import 'package:motion_ai/core/constants/hive_table_constant.dart';
import 'package:motion_ai/core/services/storage/token_service.dart';
import 'package:motion_ai/feature/audio_file/data/datasources/local/audio_local_datasource.dart';
import 'package:motion_ai/feature/audio_file/data/datasources/remote/audio_remote_datasource.dart';
import 'package:motion_ai/feature/auth/data/datasources/auth_datasource.dart';
import 'package:motion_ai/feature/workspace/data/models/workspace_hive_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motion_ai/core/services/storage/user_session_service.dart';
import 'package:motion_ai/core/services/hive/hive_service.dart';
import 'package:motion_ai/feature/audio_file/data/datasources/audio_file_datasource.dart';

// SharedPreferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError("SharedPreferences provider not overridden!");
});

// HiveService Provider
final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError("HiveService provider not overridden!");
});

// UserSessionService Provider
final userSessionServiceProvider = Provider<UserSessionService>((ref) {
  return UserSessionService(prefs: ref.read(sharedPreferencesProvider));
});

final tokenServiceProvider = Provider<TokenService>((ref) {
  throw UnimplementedError("TokenService provider not implemented!");
});

// Audio Remote Provider
final audioRemoteProvider = Provider<IAudioRemoteDatasource>((ref) {
  return AudioFileRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    tokenService: ref.read(tokenServiceProvider),
    userSessionService: ref.read(userSessionServiceProvider),
  );
});

// Audio Local Datasource Provider
final audioLocalDatasourceProvider = Provider<IAudioLocalDatasource>((ref) {
  return AudioLocalDatasource(hiveService: ref.read(hiveServiceProvider));
});

final workspaceBoxProvider = Provider<Box<WorkspaceHiveModel>>((ref) {
  return Hive.box<WorkspaceHiveModel>(HiveTableConstant.workspaceTable);
});

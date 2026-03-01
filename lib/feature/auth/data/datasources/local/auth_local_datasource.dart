import 'package:motion_ai/feature/auth/data/datasources/auth_datasource.dart';
import 'package:motion_ai/core/services/hive/hive_service.dart';
import 'package:motion_ai/core/services/storage/user_session_service.dart';
import 'package:motion_ai/feature/auth/data/models/auth_hive_model.dart';

class AuthLocalDatasource implements IAuthLocalDataSource {
  final HiveService hiveService;
  final UserSessionService userSessionService;

  AuthLocalDatasource({
    required this.hiveService,
    required this.userSessionService,
  });

  @override
  Future<AuthHiveModel> register(AuthHiveModel user) async {
    await hiveService.registerUser(user);
    return user;
  }

  @override
  Future<AuthHiveModel?> login(String email, String password) async {
    final user = await hiveService.loginUser(email, password);

    if (user != null) {
      await userSessionService.saveUserSession(
        userId: user.userId ?? '',
        userEmail: user.email,
        username: user.username ?? user.email.split('@').first,
      );

      await hiveService.init();
      await hiveService
          .setActiveUser(user.userId ?? ''); // critical for session management
    }

    return user;
  }

  @override
  Future<bool> logout() async {
    await userSessionService.clearUserSession();
    await hiveService.clearActiveUser();

    // optional: clear audio cache
    await hiveService.clearAudioFiles();
    return true;
  }

  @override
  Future<AuthHiveModel?> getCurrentUser() async {
    final email = await userSessionService.getUserEmail();
    if (email == null) return null;
    return hiveService.getUserByEmail(email);
  }

  @override
  Future<bool> deleteUser(String authId) {
    // TODO: implement deleteUser
    throw UnimplementedError();
  }

  @override
  Future<AuthHiveModel?> getUserByEmail(String email) {
    // TODO: implement getUserByEmail
    throw UnimplementedError();
  }

  @override
  Future<AuthHiveModel?> getUserById(String authId) {
    // TODO: implement getUserById
    throw UnimplementedError();
  }

  @override
  Future<bool> isEmailExists(String email) async {
    return await hiveService.isEmailExists(email);
  }

  @override
  Future<bool> updateUser(AuthHiveModel user) async {
    return hiveService.updateUser(user);
  }
}

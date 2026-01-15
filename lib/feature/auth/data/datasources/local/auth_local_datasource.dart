import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/services/hive/hive_service.dart';
import 'package:motion_ai/core/services/storage/user_session_service.dart';
import 'package:motion_ai/feature/auth/data/datasources/auth_datasource.dart';
import 'package:motion_ai/feature/auth/data/models/auth_hive_model.dart';

final authLocalDatasourceProvider = Provider.autoDispose<IAuthLocalDataSource>((
  ref,
) {
  final hiveService = ref.watch(hiveServiceProvider);
  final userSessionService = ref.read(userSessionServiceProvider);
  return AuthLocalDatasource(
    hiveService: hiveService,
    userSessionService: userSessionService,
  );
});

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
    try {
      final user = await hiveService.loginUser(email, password);
      // user ko details lai shared prefs ma save garne
      if (user != null) {
        await userSessionService.saveUserSession(
          userId: user.userId!,
          userEmail: user.email,
        );
      }

      return user;
    } catch (e) {
      return Future.value(null);
    }
  }

  @override
  Future<bool> logout() async {
    await hiveService.logout();
    return true;
  }

  @override
  Future<AuthHiveModel?> getCurrentUser() async {
    return hiveService.getCurrentUser();
  }

  @override
  Future<AuthHiveModel?> getUserById(String authId) async {
    return hiveService.getUserById(authId);
  }

  @override
  Future<AuthHiveModel?> getUserByEmail(String email) async {
    return hiveService.getUserByEmail(email);
  }

  @override
  Future<bool> isEmailExists(String email) async {
    final user = await hiveService.getUserByEmail(email);
    return user != null;
  }

  @override
  Future<bool> updateUser(AuthHiveModel user) async {
    await hiveService.updateUser(user);
    return true;
  }

  @override
  Future<bool> deleteUser(String authId) async {
    await hiveService.deleteUser(authId);
    return true;
  }
}

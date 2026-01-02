import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/services/hive/hive_service.dart';
import 'package:motion_ai/feature/auth/data/datasources/auth_datasource.dart';
import 'package:motion_ai/feature/auth/data/models/auth_hive_model.dart';

final authLocalDatasourceProvider = Provider.autoDispose<IAuthDataSource>((
  ref,
) {
  final hiveService = ref.watch(hiveServiceProvider);
  return AuthLocalDatasource(hiveService: hiveService);
});

class AuthLocalDatasource implements IAuthDataSource {
  final HiveService hiveService;

  AuthLocalDatasource({required this.hiveService});

  @override
  Future<AuthHiveModel> register(AuthHiveModel user) async {
    await hiveService.registerUser(user);
    return user;
  }

  @override
  Future<AuthHiveModel?> login(String email, String password) async {
    return hiveService.loginUser(email, password);
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

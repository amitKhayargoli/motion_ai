import 'package:motion_ai/feature/auth/data/models/auth_api_model.dart';
import 'package:motion_ai/feature/auth/data/models/auth_hive_model.dart';

abstract interface class IAuthLocalDataSource {
  Future<AuthHiveModel> register(AuthHiveModel user);
  Future<AuthHiveModel?> login(String email, String password);
  Future<AuthHiveModel?> getCurrentUser();
  Future<bool> logout();
  Future<AuthHiveModel?> getUserById(String authId);
  Future<AuthHiveModel?> getUserByEmail(String email);
  Future<bool> updateUser(AuthHiveModel user);
  Future<bool> deleteUser(String authId);
  Future<bool> isEmailExists(String email);
}

abstract interface class IAuthRemoteDataSource {
  Future<AuthApiModel> register(AuthApiModel user);
  Future<AuthApiModel?> login(String email, String password);
  Future<AuthApiModel?> getCurrentUser();
  Future<bool> logout();
  Future<List<AuthApiModel>> getAllUsers();
  Future<AuthApiModel?> getUserById(String authId);
  Future<AuthApiModel?> getUserByEmail(String email);
  Future<bool> updateUser(AuthApiModel user);
  Future<bool> deleteUser(String authId);
  Future<bool> isEmailExists(String email);
}

import 'package:motion_ai/core/services/hive/hive_service.dart';
import 'package:motion_ai/feature/auth/data/datasources/user_datasource.dart';
import 'package:motion_ai/feature/auth/data/models/user_hive_model.dart';

class UserLocalDatasource implements IUserDataSource {
  final HiveService _hiveService;
  UserLocalDatasource({required HiveService hiveService})
    : _hiveService = hiveService;
  @override
  Future<bool> createUser(UserHiveModel user) async {
    try {
      await _hiveService.registerUser(user);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteUser(String userId) async {
    try {
      await _hiveService.deleteUser(userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<UserHiveModel>> getAllUsers() async {
    try {
      return _hiveService.getAllUsers();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<UserHiveModel?> getUserById(String userId) async {
    try {
      return _hiveService.getUserById(userId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> updateUser(UserHiveModel user) async {
    try {
      _hiveService.updateUser(user);
      return true;
    } catch (e) {
      return false;
    }
  }
}

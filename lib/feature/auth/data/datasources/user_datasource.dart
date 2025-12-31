import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/auth/data/models/user_hive_model.dart';
import 'package:motion_ai/feature/auth/domain/entities/user_entity.dart';

abstract interface class IUserDataSource {
  Future<List<UserHiveModel>> getAllUsers();
  Future<UserHiveModel?> getUserById(String userId);
  Future<bool> createUser(UserHiveModel user);
  Future<bool> updateUser(UserHiveModel user);
  Future<bool> deleteUser(String userId);
}

import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/auth/data/datasources/user_datasource.dart';
import 'package:motion_ai/feature/auth/data/models/user_hive_model.dart';
import 'package:motion_ai/feature/auth/domain/entities/user_entity.dart';
import 'package:motion_ai/feature/auth/domain/repositories/user_repository.dart';

class UserRepository implements IUserRepository {
  final IUserDataSource _userDataSource;

  UserRepository({required IUserDataSource userDataSource})
    : _userDataSource = userDataSource;

  @override
  Future<Either<Failure, bool>> createUser(UserEntity user) async {
    try {
      // Converting entity to model
      final userModel = UserHiveModel.fromEntity(user);
      final result = await _userDataSource.createUser(userModel);

      if (result) {
        return const Right(true);
      }
      return const Left(LocalDatabaseFailure(message: "Failed to create User"));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteUser(String userId) async {
    try {
      final result = await _userDataSource.deleteUser(userId);
      if (result) {
        return Right(true);
      }

      return Left(LocalDatabaseFailure(message: "Failed to delete User"));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getAllUsers() async {
    try {
      final models = await _userDataSource.getAllUsers();
      final entities = UserHiveModel.toEntityList(models);
      return Right(entities);
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getUserById(String userId) async {
    try {
      final model = await _userDataSource.getUserById(userId);
      if (model != null) {
        final entity = model.toEntity();
        return Right(entity);
      }
      return Left(LocalDatabaseFailure(message: "Faield to fetch user data"));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateUser(UserEntity user) async {
    try {
      final userModel = UserHiveModel.fromEntity(user);
      final result = await _userDataSource.updateUser(userModel);

      if (result) {
        return const Right(true);
      }
      return Left(LocalDatabaseFailure(message: "Failed to update User"));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }
}

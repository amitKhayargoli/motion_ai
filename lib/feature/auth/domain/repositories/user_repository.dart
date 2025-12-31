import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/auth/domain/entities/user_entity.dart';

abstract interface class IUserRepository {
  Future<Either<Failure, List<UserEntity>>> getAllUsers();
  Future<Either<Failure, UserEntity>> getUserById(String userId);
  Future<Either<Failure, bool>> createUser(UserEntity user);
  Future<Either<Failure, bool>> updateUser(UserEntity user);
  Future<Either<Failure, bool>> deleteUser(String userId);
}

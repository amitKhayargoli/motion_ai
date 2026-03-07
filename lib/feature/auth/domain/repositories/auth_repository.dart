import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/auth/domain/entities/auth_entity.dart';

abstract interface class IAuthRepository {
  Future<Either<Failure, bool>> register(AuthEntity user);
  Future<Either<Failure, AuthEntity>> login(String email, String password);
  Future<Either<Failure, AuthEntity>> getCurrentUser();
  Future<Either<Failure, bool>> logout();
  Future<Either<Failure, List<AuthEntity>>> getAllUsers();
  Future<Either<Failure, AuthEntity>> getUserById(String userId);
  Future<Either<Failure, bool>> updateUser(AuthEntity user);
  Future<Either<Failure, bool>> deleteUser(String userId);
  Future<Either<Failure, bool>> isEmailExists(String email);
  Future<Either<Failure, String>> uploadImage(File image);
}

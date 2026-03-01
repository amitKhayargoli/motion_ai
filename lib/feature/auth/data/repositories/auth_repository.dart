import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/services/connectivity/network_info.dart';
import 'package:motion_ai/feature/auth/data/datasources/auth_datasource.dart';
import 'package:motion_ai/feature/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:motion_ai/feature/auth/data/models/auth_api_model.dart';
import 'package:motion_ai/feature/auth/data/models/auth_hive_model.dart';
import 'package:motion_ai/feature/auth/domain/entities/auth_entity.dart';
import 'package:motion_ai/feature/auth/domain/repositories/auth_repository.dart';
import 'package:motion_ai/feature/auth/presentation/providers/auth_providers.dart';

// Create provider
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final authDatasource = ref.read(authLocalDatasourceProvider);
  final authRemoteDatasource = ref.read(authRemoteProvider);
  final networkInfo = ref.read(networkInfoProvider);
  return AuthRepository(
    authDatasource: authDatasource,
    authRemoteDataSource: authRemoteDatasource,
    networkInfo: networkInfo,
  );
});

class AuthRepository implements IAuthRepository {
  final IAuthLocalDataSource _authDataSource;
  final IAuthRemoteDataSource _authRemoteDataSource;
  final NetworkInfo _networkInfo;

  AuthRepository({
    required IAuthLocalDataSource authDatasource,
    required IAuthRemoteDataSource authRemoteDataSource,
    required NetworkInfo networkInfo,
  })  : _authDataSource = authDatasource,
        _authRemoteDataSource = authRemoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, bool>> register(AuthEntity user) async {
    if (await _networkInfo.isConnected) {
      // Remote api
      try {
        final apiModel = AuthApiModel.fromEntity(user);
        await _authRemoteDataSource.register(apiModel);
        return const Right(true);
      } on DioException catch (e) {
        return Left(
          ApiFailure(
            message: e.response?.data['message'] ?? 'Registration failed',
            statusCode: e.response?.statusCode,
          ),
        );
      } catch (e) {
        return Left(ApiFailure(message: e.toString()));
      }
    } else {
      try {
        // Check if email already exists
        final existingUser = await _authDataSource.getUserByEmail(user.email);
        if (existingUser != null) {
          return Left(
            LocalDatabaseFailure(message: "Email already registered"),
          );
        }

        final authModel = AuthHiveModel(
          email: user.email,
          password: user.password,
        );
        await _authDataSource.register(authModel);
        return Right(true);
      } catch (e) {
        return Left(LocalDatabaseFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> login(
    String email,
    String password,
  ) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _authRemoteDataSource.login(email, password);
        if (model != null) {
          final entity = model.toEntity();

          // Cache user in Hive for offline access & profile screen
          final hiveModel = AuthHiveModel.fromEntity(entity);
          await _authDataSource.updateUser(hiveModel);

          return Right(entity);
        }
        return const Left(ApiFailure(message: "Invalid email or password"));
      } on DioException catch (e) {
        return Left(
          ApiFailure(
            message: e.response?.data['message'] ?? 'Login Failed',
            statusCode: e.response?.statusCode,
          ),
        );
      } catch (e) {
        return Left(LocalDatabaseFailure(message: e.toString()));
      }
    } else {
      try {
        final hiveModel = await _authDataSource.login(email, password);
        if (hiveModel != null) {
          final entity = hiveModel.toEntity();
          return Right(entity);
        }
        return const Left(LocalDatabaseFailure(message: "Invalid credentials"));
      } catch (e) {
        return Left(LocalDatabaseFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> getCurrentUser() async {
    try {
      // Return Hive data immediately — no network wait
      final localModel = await _authDataSource.getCurrentUser();
      if (localModel != null) {
        _refreshUserFromRemote(); // fire-and-forget background update
        return Right(localModel.toEntity());
      }

      // No local data at all — must block on remote (first login on a new device)
      if (await _networkInfo.isConnected) {
        final remoteModel = await _authRemoteDataSource.getCurrentUser();
        if (remoteModel != null) {
          final entity = remoteModel.toEntity();
          await _authDataSource.updateUser(AuthHiveModel.fromEntity(entity));
          return Right(entity);
        }
      }

      return const Left(LocalDatabaseFailure(message: "No user logged in"));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  /// Fire-and-forget: silently refreshes the Hive cache from the remote /me endpoint.
  void _refreshUserFromRemote() async {
    if (!await _networkInfo.isConnected) return;
    try {
      final remoteModel = await _authRemoteDataSource.getCurrentUser();
      if (remoteModel != null) {
        await _authDataSource
            .updateUser(AuthHiveModel.fromEntity(remoteModel.toEntity()));
      }
    } catch (_) {}
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      final result = await _authDataSource.logout();
      if (result) {
        return const Right(true);
      }
      return const Left(LocalDatabaseFailure(message: "Failed to logout"));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteUser(String userId) {
    // TODO: implement deleteUser
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<AuthEntity>>> getAllUsers() async {
    try {
      if (!await _networkInfo.isConnected) {
        return Left(NetworkFailure(message: "No internet connection"));
      }

      final models = await _authRemoteDataSource.getAllUsers();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> getUserById(String userId) {
    // TODO: implement getUserById
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, bool>> isEmailExists(String email) async {
    try {
      final user = await _authDataSource.getUserByEmail(email);
      return Right(user != null);
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadImage(File image) async {
    //only store in remote
    if (await _networkInfo.isConnected) {
      try {
        final fileName = await _authRemoteDataSource.uploadImage(image);
        return Right(fileName);
      } catch (e) {
        return Left(ApiFailure(message: e.toString()));
      }
    } else {
      return Left(ApiFailure(message: "No internet connection"));
    }
  }

  @override
  Future<Either<Failure, bool>> updateUser(AuthEntity user) async {
    if (!await _networkInfo.isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final apiModel = AuthApiModel.fromEntity(user);
      await _authRemoteDataSource.updateUser(apiModel);

      // Update the local Hive cache to reflect the changes
      final hiveModel = AuthHiveModel.fromEntity(user);
      await _authDataSource.updateUser(hiveModel);

      return const Right(true);
    } on DioException catch (e) {
      return Left(
        ApiFailure(
          message: e.response?.data['message'] ?? 'Update failed',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }
}

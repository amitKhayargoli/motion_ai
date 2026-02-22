import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/services/connectivity/network_info.dart';
import 'package:motion_ai/feature/workspace/data/datasources/local/workspace_local_datasource.dart';
import 'package:motion_ai/feature/workspace/data/datasources/remote/workspace_remote_datasource.dart';
import 'package:motion_ai/feature/workspace/data/datasources/workspace_datasource.dart';
import 'package:motion_ai/feature/workspace/data/models/workspace_api_model.dart';
import 'package:motion_ai/feature/workspace/data/models/workspace_hive_model.dart';
import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';
import 'package:motion_ai/feature/workspace/domain/repositories/workspace_repository.dart';

final workspaceRepositoryProvider = Provider<IWorkspaceRepository>((ref) {
  final local = ref.read(workspaceLocalDatasourceProvider);
  final remote = ref.read(workspaceRemoteDatasourceProvider);
  final networkInfo = ref.read(networkInfoProvider);

  return WorkspaceRepository(
    local: local,
    remote: remote,
    networkInfo: networkInfo,
  );
});

class WorkspaceRepository implements IWorkspaceRepository {
  final IWorkspaceLocalDataSource _local;
  final IWorkspaceRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  WorkspaceRepository({
    required IWorkspaceLocalDataSource local,
    required IWorkspaceRemoteDataSource remote,
    required NetworkInfo networkInfo,
  }) : _local = local,
       _remote = remote,
       _networkInfo = networkInfo;

  String _dioMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null)
      return data['message'].toString();
    return fallback;
  }

  @override
  Future<Either<Failure, WorkspaceEntity>> createWorkspace(String name) async {
    final connected = await _networkInfo.isConnected;
    print("WS createWorkspace: connected=$connected name=$name");

    if (!connected) {
      return const Left(NetworkFailure(message: "No internet connection"));
    }

    print("WS createWorkspace: calling remote...");
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: "No internet connection"));
    }

    try {
      final created = await _remote.createWorkspace(name);
      final entity = created.toEntity();

      await _local.upsertWorkspace(WorkspaceHiveModel.fromEntity(entity));
      return Right(entity);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = "Failed to create workspace";

      if (data is Map) {
        if (data['message'] != null) message = data['message'].toString();
        if (data['error'] != null) message = data['error'].toString();
      }

      return Left(
        ApiFailure(message: message, statusCode: e.response?.statusCode),
      );
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WorkspaceEntity>>> getMyWorkspaces() async {
    if (await _networkInfo.isConnected) {
      try {
        final remoteList = await _remote.getMyWorkspaces();
        final entities = remoteList.map((m) => m.toEntity()).toList();

        await _local.replaceAll(
          entities.map((e) => WorkspaceHiveModel.fromEntity(e)).toList(),
        );
        return Right(entities);
      } on DioException catch (e) {
        // fallback to cache
        try {
          final cached = await _local.getAllWorkspaces();
          return Right(cached.map((m) => m.toEntity()).toList());
        } catch (_) {
          return Left(
            ApiFailure(
              message: _dioMessage(e, 'Failed to fetch workspaces'),
              statusCode: e.response?.statusCode,
            ),
          );
        }
      } catch (e) {
        return Left(ApiFailure(message: e.toString()));
      }
    } else {
      try {
        final list = await _local.getAllWorkspaces();
        return Right(list.map((m) => m.toEntity()).toList());
      } catch (e) {
        return Left(LocalDatabaseFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, WorkspaceEntity>> getWorkspaceById(
    String workspaceId,
  ) async {
    try {
      final local = await _local.getWorkspaceById(workspaceId);
      if (local != null) return Right(local.toEntity());
    } catch (_) {}

    if (!await _networkInfo.isConnected) {
      return const Left(LocalDatabaseFailure(message: "Workspace not found"));
    }

    try {
      final remote = await _remote.getWorkspaceById(workspaceId);
      if (remote == null)
        return const Left(ApiFailure(message: "Workspace not found"));

      final entity = remote.toEntity();
      await _local.upsertWorkspace(WorkspaceHiveModel.fromEntity(entity));
      return Right(entity);
    } on DioException catch (e) {
      return Left(
        ApiFailure(
          message: _dioMessage(e, 'Failed to fetch workspace'),
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteWorkspace(String workspaceId) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remote.deleteWorkspace(workspaceId);
        await _local.deleteWorkspace(workspaceId);
        return const Right(true);
      } on DioException catch (e) {
        return Left(
          ApiFailure(
            message: _dioMessage(e, 'Failed to delete workspace'),
            statusCode: e.response?.statusCode,
          ),
        );
      } catch (e) {
        return Left(ApiFailure(message: e.toString()));
      }
    } else {
      // choose: local delete only OR block offline delete
      try {
        await _local.deleteWorkspace(workspaceId);
        return const Right(true);
      } catch (e) {
        return Left(LocalDatabaseFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, WorkspaceEntity>> joinByInviteLink(
    String inviteLink,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(message: "No internet connection"));
    }

    try {
      final joined = await _remote.joinByInviteLink(inviteLink);
      final entity = joined.toEntity();

      await _local.upsertWorkspace(WorkspaceHiveModel.fromEntity(entity));

      return Right(entity);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = "Failed to join workspace";

      if (data is Map) {
        if (data['message'] != null) {
          message = data['message'];
        } else if (data['error'] != null) {
          message = data['error'];
        }
      }

      return Left(
        ApiFailure(message: message, statusCode: e.response?.statusCode),
      );
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }
}

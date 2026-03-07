import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/services/connectivity/network_info.dart';
import 'package:motion_ai/feature/tasks/data/datasources/task_datasource.dart';
import 'package:motion_ai/feature/tasks/data/models/task_hive_model.dart';
import 'package:motion_ai/feature/tasks/domain/entities/task_entity.dart';
import 'package:motion_ai/feature/tasks/domain/repositories/task_repository.dart';
import 'package:uuid/uuid.dart';

class TaskRepository implements ITaskRepository {
  final ITaskLocalDataSource local;
  final ITaskRemoteDataSource remote;
  final NetworkInfo networkInfo;

  TaskRepository({
    required this.local,
    required this.remote,
    required this.networkInfo,
  });

  static const _pendingDeleteBox = "tasks_pending_delete";
  static const _idMapBox = "tasks_id_map";

  Future<Box> _openDeleteQueue() => Hive.openBox(_pendingDeleteBox);
  Future<Box> _openIdMap() => Hive.openBox(_idMapBox);

  // ---------- GET (local-first; remote only on forceRefresh) ----------
  @override
  Future<Either<Failure, List<TaskEntity>>> getWorkspaceTasks(
      String workspaceId,
      {bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        final isOnline = await networkInfo.isConnected;

        if (isOnline) {
          try {
            final remoteTasks = await remote.getWorkspaceTasks(workspaceId);
            final remoteEntities =
                remoteTasks.map((m) => m.toEntity()).toList();

            final pending = await local.getPendingWorkspaceTasks(workspaceId);
            final pendingIds = pending.map((p) => p.id).toSet();

            final toCache = remoteEntities
                .where((e) => !pendingIds.contains(e.id))
                .map((e) => TaskHiveModel.fromEntity(e, syncStatus: 0))
                .toList();

            await local.upsertTasks(toCache);
          } catch (_) {
            // Remote fetch failed -> fall through to return local data
          }
        }
      }

      final cached = await local.getWorkspaceTasks(workspaceId);
      final localEntities = cached.map((m) => m.toEntity()).toList()
        ..sort((a, b) {
          final ad = a.updatedAt ?? a.createdAt ?? DateTime(0);
          final bd = b.updatedAt ?? b.createdAt ?? DateTime(0);
          return bd.compareTo(ad);
        });

      return Right(localEntities);
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  Future<void> syncWorkspaceTasks(String workspaceId) async {
    if (!await networkInfo.isConnected) return;

    final pending = await local.getPendingWorkspaceTasks(workspaceId);

    for (final t in pending) {
      final taskId = t.id;

      // pending CREATE (syncStatus == 1)
      if (t.syncStatus == 1) {
        try {
          final api = await remote.createTask(
            workspaceId: workspaceId,
            title: t.title,
            description: t.description,
            priority: t.priority,
            dueDate: t.dueDate,
          );
          final server = api.toEntity();

          final mapBox = await _openIdMap();
          await mapBox.put(taskId, server.id);

          await local.deleteTask(taskId);
          await local
              .upsertTask(TaskHiveModel.fromEntity(server, syncStatus: 0));
        } catch (_) {
          // keep pending
        }
      }

      // pending UPDATE (syncStatus == 2)
      if (t.syncStatus == 2) {
        try {
          String? serverId = taskId;

          if (taskId.startsWith("local_")) {
            final mapBox = await _openIdMap();
            serverId = mapBox.get(taskId)?.toString();
          }

          if (serverId == null) continue;

          final api = await remote.updateTask(
            taskId: serverId,
            title: t.title,
            description: t.description,
            isCompleted: t.isCompleted,
            priority: t.priority,
            dueDate: t.dueDate,
          );
          final updated = api.toEntity();

          await local.upsertTask(
            t.copyWith(syncStatus: 0, updatedAt: updated.updatedAt),
          );
        } catch (_) {
          // keep pending
        }
      }
    }

    // Sync deletes
    final q = await _openDeleteQueue();
    final keys = q.keys.toList();

    for (final k in keys) {
      try {
        await remote.deleteTask(k.toString());
        await q.delete(k);
      } catch (_) {
        // keep in queue
      }
    }

    // Pull latest from API
    await getWorkspaceTasks(workspaceId, forceRefresh: true);
  }

  // ---------- CREATE (local first, then remote) ----------
  @override
  Future<Either<Failure, TaskEntity>> createTask(
    String workspaceId,
    String title, {
    String? description,
    String? priority,
    DateTime? dueDate,
  }) async {
    try {
      final now = DateTime.now();
      final localId = "local_${const Uuid().v4()}";

      final localEntity = TaskEntity(
        id: localId,
        workspaceId: workspaceId,
        title: title,
        description: description,
        priority: priority,
        dueDate: dueDate,
        createdAt: now,
        updatedAt: now,
        syncStatus: TaskSyncStatus.pendingCreate,
      );

      await local
          .upsertTask(TaskHiveModel.fromEntity(localEntity, syncStatus: 1));

      if (!await networkInfo.isConnected) {
        return Right(localEntity);
      }

      try {
        final api = await remote.createTask(
          workspaceId: workspaceId,
          title: title,
          description: description,
          priority: priority,
          dueDate: dueDate,
        );
        final server = api.toEntity();

        final mapBox = await _openIdMap();
        await mapBox.put(localId, server.id);

        await local.deleteTask(localId);
        await local.upsertTask(TaskHiveModel.fromEntity(server, syncStatus: 0));

        return Right(server);
      } catch (_) {
        return Right(localEntity);
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  // ---------- UPDATE (local first, then remote best-effort) ----------
  @override
  Future<Either<Failure, TaskEntity>> updateTask(
    String taskId, {
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    DateTime? dueDate,
  }) async {
    try {
      final existing = await local.getTaskById(taskId);
      if (existing == null) {
        return const Left(
            LocalDatabaseFailure(message: "Task not found locally"));
      }

      final now = DateTime.now();

      final localUpdated = existing.copyWith(
        title: title,
        description: description,
        isCompleted: isCompleted,
        priority: priority,
        dueDate: dueDate,
        updatedAt: now,
        syncStatus: existing.syncStatus == 1 ? 1 : 2,
      );
      await local.upsertTask(localUpdated);

      if (!await networkInfo.isConnected) return Right(localUpdated.toEntity());

      String? serverId;
      if (taskId.startsWith("local_")) {
        final mapBox = await _openIdMap();
        serverId = mapBox.get(taskId)?.toString();
      } else {
        serverId = taskId;
      }

      if (serverId == null) {
        return Right(localUpdated.toEntity());
      }

      try {
        final api = await remote.updateTask(
          taskId: serverId,
          title: title,
          description: description,
          isCompleted: isCompleted,
          priority: priority,
          dueDate: dueDate,
        );
        final updatedEntity = api.toEntity();

        if (taskId.startsWith("local_")) {
          await local.deleteTask(taskId);
          await local.upsertTask(
              TaskHiveModel.fromEntity(updatedEntity, syncStatus: 0));
          final mapBox = await _openIdMap();
          await mapBox.delete(taskId);
        } else {
          await local.upsertTask(
            localUpdated.copyWith(
                syncStatus: 0, updatedAt: updatedEntity.updatedAt ?? now),
          );
        }

        return Right(updatedEntity);
      } catch (_) {
        return Right(localUpdated.toEntity());
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  // ---------- DELETE (local first, then remote best-effort) ----------
  @override
  Future<Either<Failure, bool>> deleteTask(String taskId) async {
    try {
      await local.deleteTask(taskId);

      String? serverId;
      if (taskId.startsWith("local_")) {
        final mapBox = await _openIdMap();
        serverId = mapBox.get(taskId)?.toString();
        if (serverId == null) return const Right(true);
      } else {
        serverId = taskId;
      }

      if (!await networkInfo.isConnected) {
        final q = await _openDeleteQueue();
        await q.put(serverId, DateTime.now().toIso8601String());
        return const Right(true);
      }

      try {
        await remote.deleteTask(serverId);
        final q = await _openDeleteQueue();
        if (q.containsKey(serverId)) await q.delete(serverId);
        return const Right(true);
      } catch (_) {
        final q = await _openDeleteQueue();
        await q.put(serverId, DateTime.now().toIso8601String());
        return const Right(true);
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }
}

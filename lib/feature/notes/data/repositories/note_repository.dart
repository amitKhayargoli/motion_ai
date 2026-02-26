import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/services/connectivity/network_info.dart';
import 'package:motion_ai/feature/notes/data/datasources/note_datasource.dart';
import 'package:motion_ai/feature/notes/data/models/note_hive_model.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/domain/repositories/notes_repository.dart';
import 'package:uuid/uuid.dart';

class NoteRepository implements INoteRepository {
  final INoteLocalDataSource local;
  final INoteRemoteDataSource remote;
  final NetworkInfo networkInfo;

  NoteRepository({
    required this.local,
    required this.remote,
    required this.networkInfo,
  });

  // Queue for deletes when offline / api fails
  static const _pendingDeleteBox = "notes_pending_delete";

  Future<Box> _openDeleteQueue() => Hive.openBox(_pendingDeleteBox);

  // ---------------- GET ----------------
  @override
  Future<Either<Failure, List<NoteEntity>>> getWorkspaceNotes(
    String workspaceId,
  ) async {
    try {
      // 1) Always show local first (fast)
      final cached = await local.getWorkspaceNotes(workspaceId);
      final pending = await local.getPendingWorkspaceNotes(workspaceId);

      // Merge by "display id" (serverId if exists)
      final map = <String, NoteHiveModel>{};

      for (final n in cached) {
        map[n.serverId ?? n.id] = n;
      }
      for (final n in pending) {
        map[n.serverId ?? n.id] = n;
      }

      final localEntities = map.values.map((m) => m.toEntity()).toList()
        ..sort((a, b) {
          final ad = a.updatedAt ?? a.createdAt ?? DateTime(0);
          final bd = b.updatedAt ?? b.createdAt ?? DateTime(0);
          return bd.compareTo(ad);
        });

      // 2) If online, refresh cache in background style
      final isOnline = await networkInfo.isConnected;
      if (!isOnline) return Right(localEntities);

      try {
        final remoteNotes = await remote.getWorkspaceNotes(workspaceId);
        final entities = remoteNotes.map((m) => m.toEntity()).toList();

        // cache remote into hive (but do NOT overwrite pending local edits)
        final hiveModels = entities.map((e) {
          // If there is a pending local edit for this server id, keep local version
          final existing = map[e.id];
          if (existing != null && existing.syncStatus != 0) {
            return existing; // keep pending local
          }
          return NoteHiveModel.fromEntity(e, syncStatus: 0, serverId: e.id);
        }).toList();

        await local.upsertNotes(hiveModels);

        // return merged view again after caching
        final after = await local.getWorkspaceNotes(workspaceId);
        final afterPending = await local.getPendingWorkspaceNotes(workspaceId);

        final merged = <String, NoteHiveModel>{};
        for (final n in after) merged[n.serverId ?? n.id] = n;
        for (final n in afterPending) merged[n.serverId ?? n.id] = n;

        final finalEntities = merged.values.map((m) => m.toEntity()).toList()
          ..sort((a, b) {
            final ad = a.updatedAt ?? a.createdAt ?? DateTime(0);
            final bd = b.updatedAt ?? b.createdAt ?? DateTime(0);
            return bd.compareTo(ad);
          });

        return Right(finalEntities);
      } catch (_) {
        // If refresh fails, still return local
        return Right(localEntities);
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  // ---------------- CREATE (local first, then remote) ----------------
  @override
  Future<Either<Failure, NoteEntity>> createNote(
    String workspaceId,
    String title,
    String content,
  ) async {
    try {
      final now = DateTime.now();
      final tempLocalId = "local_${const Uuid().v4()}";

      // 1) Local immediately as pendingCreate
      final localEntity = NoteEntity(
        id: tempLocalId,
        workspaceId: workspaceId,
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
      );

      await local.upsertNote(
        NoteHiveModel.fromEntity(
          localEntity,
          syncStatus: 1, // pendingCreate
          serverId: null,
          localId: tempLocalId,
        ),
      );

      // 2) Try remote (best effort)
      final isOnline = await networkInfo.isConnected;
      if (!isOnline) return Right(localEntity);

      try {
        final apiModel = await remote.createNote(
          workspaceId: workspaceId,
          title: title,
          content: content,
        );
        final server = apiModel.toEntity();

        // Replace local temp with synced server note:
        // - delete temp key
        await local.deleteNote(tempLocalId);

        // - save server note as synced
        await local.upsertNote(
          NoteHiveModel.fromEntity(
            server,
            syncStatus: 0,
            serverId: server.id,
            localId: server.id,
          ),
        );

        return Right(server);
      } catch (e) {
        // keep local pendingCreate
        return Right(localEntity);
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  // ---------------- UPDATE (local first ALWAYS, then remote) ----------------
  @override
  Future<Either<Failure, NoteEntity>> updateNote(
    String noteId,
    String title,
    String content,
  ) async {
    try {
      final existing = await local.getNoteById(noteId);

      // If editing a note that is stored with different local id:
      // We use noteId as "key". Your UI should pass local hive id ideally.
      // If not found, we still create a local shadow.
      final now = DateTime.now();

      final localModel = (existing ??
              NoteHiveModel(
                id: noteId,
                workspaceId: "",
                title: title,
                content: content,
                createdAt: now,
                updatedAt: now,
              ))
          .copyWith(
        title: title,
        content: content,
        updatedAt: now,
        syncStatus: (existing?.syncStatus == 1)
            ? 1
            : 2, // keep pendingCreate else pendingUpdate
      );

      // 1) Save locally first (instant UX)
      await local.upsertNote(localModel);

      // 2) Try remote best effort (if we have a serverId)
      final isOnline = await networkInfo.isConnected;
      if (!isOnline) return Right(localModel.toEntity());

      final serverId = localModel.serverId ??
          (localModel.id.startsWith("local_") ? null : localModel.id);
      if (serverId == null) {
        // Can't update server yet (was never created). Leave pendingCreate.
        return Right(localModel.toEntity());
      }

      try {
        final updated = await remote.updateNote(
          noteId: serverId,
          title: title,
          content: content,
        );
        final entity = updated.toEntity();

        // mark synced locally, keep the same hive key (noteId)
        await local.upsertNote(
          localModel.copyWith(
            // keep local key id as-is, but store correct serverId
            serverId: entity.id,
            syncStatus: 0,
            updatedAt: entity.updatedAt ?? now,
          ),
        );

        return Right(entity);
      } catch (_) {
        // keep pendingUpdate
        return Right(localModel.toEntity());
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  // ---------------- DELETE (local first ALWAYS, then remote) ----------------
  @override
  Future<Either<Failure, bool>> deleteNote(String noteId) async {
    try {
      final existing = await local.getNoteById(noteId);

      // 1) Delete locally immediately
      await local.deleteNote(noteId);

      // 2) Try remote best effort
      final isOnline = await networkInfo.isConnected;
      final serverId = existing?.serverId ??
          (existing != null && !existing.id.startsWith("local_")
              ? existing.id
              : null);

      // If it was purely local (never created on server), we're done
      if (serverId == null) return const Right(true);

      if (!isOnline) {
        // enqueue for later
        final box = await _openDeleteQueue();
        await box.put(serverId, DateTime.now().toIso8601String());
        return const Right(true);
      }

      try {
        await remote.deleteNote(serverId);
        // also remove from delete queue if it exists
        final box = await _openDeleteQueue();
        if (box.containsKey(serverId)) await box.delete(serverId);
        return const Right(true);
      } catch (_) {
        // enqueue for later
        final box = await _openDeleteQueue();
        await box.put(serverId, DateTime.now().toIso8601String());
        return const Right(true);
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }
}

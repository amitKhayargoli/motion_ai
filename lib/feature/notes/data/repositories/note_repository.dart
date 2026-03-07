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

  static const _pendingDeleteBox = "notes_pending_delete";
  static const _idMapBox = "notes_id_map"; // localId -> serverId

  Future<Box> _openDeleteQueue() => Hive.openBox(_pendingDeleteBox);
  Future<Box> _openIdMap() => Hive.openBox(_idMapBox);

  // ---------- GET (local-first; remote only on forceRefresh) ----------
  @override
  Future<Either<Failure, List<NoteEntity>>> getWorkspaceNotes(
      String workspaceId,
      {bool forceRefresh = false}) async {
    try {
      // If forceRefresh requested, pull from remote and cache locally
      if (forceRefresh) {
        final isOnline = await networkInfo.isConnected;

        if (isOnline) {
          try {
            final remoteNotes = await remote.getWorkspaceNotes(workspaceId);
            final remoteEntities =
                remoteNotes.map((m) => m.toEntity()).toList();

            // Don't overwrite pending locals
            final pending = await local.getPendingWorkspaceNotes(workspaceId);
            final pendingIds = pending.map((p) => p.id).toSet();

            final toCache = remoteEntities
                .where((e) => !pendingIds.contains(e.id))
                .map((e) => NoteHiveModel.fromEntity(e, syncStatus: 0))
                .toList();

            await local.upsertNotes(toCache);
          } catch (_) {
            // Remote fetch failed → fall through to return local data
          }
        }
      }

      // Always return local data
      final cached = await local.getWorkspaceNotes(workspaceId);
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

  Future<void> syncWorkspaceNotes(String workspaceId) async {
    // only run when online
    if (!await networkInfo.isConnected) return;

    // 1) Sync pending creates/updates
    final pending = await local.getPendingWorkspaceNotes(workspaceId);

    for (final n in pending) {
      final noteId = n.id;

      // pending CREATE (syncStatus == 1)
      if (n.syncStatus == 1) {
        try {
          final api = await remote.createNote(
            workspaceId: workspaceId,
            title: n.title,
            content: n.content,
          );
          final server = api.toEntity();

          final mapBox = await _openIdMap();
          await mapBox.put(noteId, server.id);

          // replace localId note with server note
          await local.deleteNote(noteId);
          await local
              .upsertNote(NoteHiveModel.fromEntity(server, syncStatus: 0));
        } catch (_) {
          // keep pending
        }
      }

      // pending UPDATE (syncStatus == 2)
      if (n.syncStatus == 2) {
        try {
          String? serverId = noteId;

          // if local temp id, resolve serverId
          if (noteId.startsWith("local_")) {
            final mapBox = await _openIdMap();
            serverId = mapBox.get(noteId)?.toString();
          }

          if (serverId == null) continue; // not created on server yet

          final api = await remote.updateNote(
            noteId: serverId,
            title: n.title,
            content: n.content,
          );
          final updated = api.toEntity();

          // mark synced locally
          await local.upsertNote(
            n.copyWith(syncStatus: 0, updatedAt: updated.updatedAt),
          );
        } catch (_) {
          // keep pending
        }
      }
    }

    // 2) Sync deletes
    final q = await _openDeleteQueue();
    final keys = q.keys.toList();

    for (final k in keys) {
      try {
        await remote.deleteNote(k.toString());
        await q.delete(k);
      } catch (_) {
        // keep in queue
      }
    }

    // 3) Pull latest from API and cache to Hive
    await getWorkspaceNotes(workspaceId, forceRefresh: true);
  }

  // ---------- CREATE (local first, then remote, replace localId) ----------
  @override
  Future<Either<Failure, NoteEntity>> createNote(
    String workspaceId,
    String title,
    String content,
  ) async {
    try {
      final now = DateTime.now();
      final localId = "local_${const Uuid().v4()}";

      final localEntity = NoteEntity(
        id: localId,
        workspaceId: workspaceId,
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
        syncStatus: NoteSyncStatus.pendingCreate,
      );

      await local
          .upsertNote(NoteHiveModel.fromEntity(localEntity, syncStatus: 1));

      if (!await networkInfo.isConnected) {
        return Right(localEntity);
      }

      try {
        final api = await remote.createNote(
          workspaceId: workspaceId,
          title: title,
          content: content,
        );
        final server = api.toEntity();

        // map local -> server
        final mapBox = await _openIdMap();
        await mapBox.put(localId, server.id);

        // replace in hive: delete temp, insert server note
        await local.deleteNote(localId);
        await local.upsertNote(NoteHiveModel.fromEntity(server, syncStatus: 0));

        return Right(server);
      } catch (_) {
        // keep pendingCreate locally
        return Right(localEntity);
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  // ---------- UPDATE (ALWAYS local first, then remote best-effort) ----------
  @override
  Future<Either<Failure, NoteEntity>> updateNote(
    String noteId,
    String title,
    String content,
  ) async {
    try {
      final existing = await local.getNoteById(noteId);
      if (existing == null) {
        return const Left(
            LocalDatabaseFailure(message: "Note not found locally"));
      }

      final now = DateTime.now();

      // 1) local first
      final localUpdated = existing.copyWith(
        title: title,
        content: content,
        updatedAt: now,
        syncStatus: existing.syncStatus == 1
            ? 1
            : 2, // keep pendingCreate else pendingUpdate
      );
      await local.upsertNote(localUpdated);

      // 2) remote best-effort
      if (!await networkInfo.isConnected) return Right(localUpdated.toEntity());

      // if it's local_xxx we must resolve serverId from idMap
      String? serverId;
      if (noteId.startsWith("local_")) {
        final mapBox = await _openIdMap();
        serverId = mapBox.get(noteId)?.toString();
      } else {
        serverId = noteId;
      }

      if (serverId == null) {
        // can't update server until created
        return Right(localUpdated.toEntity());
      }

      try {
        final api = await remote.updateNote(
          noteId: serverId,
          title: title,
          content: content,
        );
        final updatedEntity = api.toEntity();

        if (noteId.startsWith("local_")) {
          // replace localId with serverId in hive
          await local.deleteNote(noteId);
          await local.upsertNote(
              NoteHiveModel.fromEntity(updatedEntity, syncStatus: 0));
          final mapBox = await _openIdMap();
          await mapBox.delete(noteId);
        } else {
          await local.upsertNote(
            localUpdated.copyWith(
                syncStatus: 0, updatedAt: updatedEntity.updatedAt ?? now),
          );
        }

        return Right(updatedEntity);
      } catch (_) {
        // keep pendingUpdate locally
        return Right(localUpdated.toEntity());
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  // ---------- DELETE (ALWAYS local first, then remote best-effort) ----------
  @override
  Future<Either<Failure, bool>> deleteNote(String noteId) async {
    try {
      final existing = await local.getNoteById(noteId);

      // 1) local first
      await local.deleteNote(noteId);

      // resolve server id if needed
      String? serverId;
      if (noteId.startsWith("local_")) {
        final mapBox = await _openIdMap();
        serverId = mapBox.get(noteId)?.toString();
        // if it's purely local (never created), we're done
        if (serverId == null) return const Right(true);
      } else {
        serverId = noteId;
      }

      // 2) remote best-effort
      if (!await networkInfo.isConnected) {
        final q = await _openDeleteQueue();
        await q.put(serverId, DateTime.now().toIso8601String());
        return const Right(true);
      }

      try {
        await remote.deleteNote(serverId);
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

  @override
  Future<Either<Failure, NoteEntity>> transcribeAudio({
    required String audioFileId,
    required String workspaceId,
    String? noteTitle,
  }) async {
    try {
      final apiModel = await remote.transcribeAudio(
        audioFileId: audioFileId,
        workspaceId: workspaceId,
        noteTitle: noteTitle,
      );
      final entity = apiModel.toEntity();

      // cache locally
      await local.upsertNote(NoteHiveModel.fromEntity(entity, syncStatus: 0));

      return Right(entity);
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, NoteEntity?>> getTranscriptByAudioFileId(
    String audioFileId,
  ) async {
    try {
      // 1) local first
      final cached = await local.getTranscriptByAudioFileId(audioFileId);
      final localEntity = cached?.toEntity();

      // 2) if offline -> return local
      final isOnline = await networkInfo.isConnected;
      if (!isOnline) return Right(localEntity);

      // 3) online: fetch remote + cache
      try {
        final remoteNote = await remote.getTranscriptByAudioFileId(audioFileId);
        if (remoteNote == null) {
          return Right(localEntity); // keep local if exists
        }

        final entity = remoteNote.toEntity();
        await local.upsertNote(NoteHiveModel.fromEntity(entity, syncStatus: 0));
        return Right(entity);
      } catch (_) {
        // remote failed -> return local
        return Right(localEntity);
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }
}

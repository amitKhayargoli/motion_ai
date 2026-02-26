import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/core/services/connectivity/network_info.dart';
import 'package:motion_ai/feature/audio_file/data/datasources/audio_file_datasource.dart';
import 'package:motion_ai/feature/audio_file/data/datasources/remote/audio_remote_datasource.dart';
import 'package:motion_ai/feature/audio_file/domain/entities/audio_file_entity.dart';
import 'package:motion_ai/feature/audio_file/domain/repositories/audio_file_repository.dart';

final audioFileRepositoryProvider = Provider<IAudioFileRepository>((ref) {
  final local = ref.read(audioLocalDatasourceProvider);
  final remote = ref.read(audioFileRemoteDatasourceProvider);
  final networkInfo = ref.read(networkInfoProvider);

  return AudioFileRepository(
    localDatasource: local,
    remoteDatasource: remote,
    networkInfo: networkInfo,
  );
});

class AudioFileRepository implements IAudioFileRepository {
  final IAudioLocalDatasource _localDatasource;
  final IAudioRemoteDatasource _remoteDatasource;
  final NetworkInfo _networkInfo;

  AudioFileRepository({
    required IAudioLocalDatasource localDatasource,
    required IAudioRemoteDatasource remoteDatasource,
    required NetworkInfo networkInfo,
  })  : _localDatasource = localDatasource,
        _remoteDatasource = remoteDatasource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, AudioFileEntity>> saveAudio(
    AudioFileEntity audio,
  ) async {
    try {
      // Mark as pendingUpload (1) so sync picks it up later
      final hive = audio.toHiveModel().copyWith(syncStatus: 1);
      await _localDatasource.saveAudio(hive);
      return Right(AudioFileEntity.fromHiveModel(hive));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AudioFileEntity>> uploadAudio(
    AudioFileEntity audio,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(
        NetworkFailure(message: 'No internet connection for upload'),
      );
    }

    try {
      final apiModel = await _remoteDatasource.uploadAudio(
        filePath: audio.localPath,
        durationSeconds: audio.durationSeconds!,
        title: audio.title,
      );

      // Server returns the canonical ID — use it
      final serverId = apiModel.id;

      // If audio had a local-only ID, remove the old Hive entry
      if (audio.id.isNotEmpty && serverId != null && audio.id != serverId) {
        await _localDatasource.deleteAudio(audio.id);
      }

      // Upload succeeded — save with server ID, mark synced (0)
      final updatedAudio = audio.copyWith(
        id: serverId ?? audio.id,
        cloudUrl: apiModel.cloudUrl,
        fileName: apiModel.fileName,
        syncStatus: 0,
      );

      await _localDatasource.saveAudio(updatedAudio.toHiveModel());

      return Right(updatedAudio);
    } on DioException catch (e) {
      return Left(
        ApiFailure(
          message: e.response?.data['message'] ?? 'Upload failed',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AudioFileEntity>>> getUserAudioFiles(
    String userId,
  ) async {
    try {
      // 1. Try fetching from Remote (MongoDB)
      final remoteAudios = await _remoteDatasource.getAudiosByUploader(userId);

      // 2. Cache remote audios while preserving existing localPaths from Hive
      for (final remote in remoteAudios) {
        final existing = await _localDatasource.getAudioById(remote.id!);
        final hiveModel = remote.toHiveModel().copyWith(
          localPath: existing?.localPath ?? '',
          title: existing?.title, // preserve user-set title
        );
        await _localDatasource.saveAudio(hiveModel);
      }

      // 3. Read back from Hive — includes remote entries (with preserved
      //    localPaths) plus any local-only recordings not yet uploaded
      final cached = await _localDatasource.getStoredAudios();
      return Right(cached.map((m) => AudioFileEntity.fromHiveModel(m)).toList());
    } catch (e) {
      final localAudios = await _localDatasource.getStoredAudios();

      if (localAudios.isNotEmpty) {
        return Right(
          localAudios
              .map((model) => AudioFileEntity.fromHiveModel(model))
              .toList(),
        );
      }

      return Left(ApiFailure(message: "Remote failed and no local data found"));
    }
  }

  @override
  Future<Either<Failure, AudioFileEntity>> updateAudio(
    String audioId, {
    String? title,
  }) async {
    if (audioId.isEmpty) {
      return const Left(
        LocalDatabaseFailure(message: 'Cannot update audio with empty ID'),
      );
    }

    try {
      final existing = await _localDatasource.getAudioById(audioId);
      if (existing == null) {
        return const Left(
          LocalDatabaseFailure(message: 'Audio not found locally'),
        );
      }

      final isOnline = existing.cloudUrl.isNotEmpty &&
          await _networkInfo.isConnected;

      // 1. Update locally first — mark pendingUpdate (2) if offline
      final updated = existing.copyWith(
        title: title,
        syncStatus: isOnline ? existing.syncStatus : 2,
      );
      await _localDatasource.saveAudio(updated);

      // 2. Best-effort remote sync (only if audio was already uploaded)
      if (isOnline) {
        try {
          await _remoteDatasource.updateAudio(audioId, title: title);
          // Remote succeeded — mark synced
          final synced = updated.copyWith(syncStatus: 0);
          await _localDatasource.saveAudio(synced);
          return Right(AudioFileEntity.fromHiveModel(synced));
        } catch (_) {
          // Remote failed — keep pendingUpdate so sync picks it up
          final pending = updated.copyWith(syncStatus: 2);
          await _localDatasource.saveAudio(pending);
        }
      }

      return Right(AudioFileEntity.fromHiveModel(updated));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAudio(String audioId) async {
    try {
      // Best-effort remote delete first
      if (await _networkInfo.isConnected) {
        try {
          await _remoteDatasource.deleteAudio(audioId);
        } catch (_) {
          // Remote delete failed silently
        }
      }

      await _localDatasource.deleteAudio(audioId);
      return const Right(true);
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  // ================== SYNC ==================

  @override
  Future<void> syncAudioFiles() async {
    debugPrint('[AudioSync] Starting sync...');

    // Phase 1: Push pending uploads (syncStatus == 1)
    final pending = await _localDatasource.getPendingAudios();
    for (final hive in pending) {
      debugPrint('[AudioSync] Pending entry id=${hive.id} '
          'title=${hive.title} duration=${hive.durationSeconds} '
          'syncStatus=${hive.syncStatus} localPath=${hive.localPath}');
      try {
        if (hive.syncStatus == 1 && hive.localPath.isNotEmpty) {
          // pendingUpload — upload the file
          final apiModel = await _remoteDatasource.uploadAudio(
            filePath: hive.localPath,
            durationSeconds: hive.durationSeconds,
            title: hive.title,
          );

          final serverId = apiModel.id;

          // Remove old local-ID entry from Hive
          if (serverId != null && hive.id != serverId) {
            await _localDatasource.deleteAudio(hive.id);
          }

          // Save with server ID
          final synced = hive.copyWith(
            id: serverId ?? hive.id,
            cloudUrl: apiModel.cloudUrl,
            fileName: apiModel.fileName,
            syncStatus: 0,
          );
          await _localDatasource.saveAudio(synced);
          debugPrint('[AudioSync] Uploaded pending audio: ${synced.id}');
        } else if (hive.syncStatus == 2 &&
            hive.cloudUrl.isNotEmpty &&
            hive.id.isNotEmpty) {
          // pendingUpdate — PATCH title to server
          await _remoteDatasource.updateAudio(hive.id, title: hive.title);
          final synced = hive.copyWith(syncStatus: 0);
          await _localDatasource.saveAudio(synced);
          debugPrint('[AudioSync] Updated pending audio: ${hive.id}');
        }
      } catch (e) {
        debugPrint('[AudioSync] Failed to sync audio ${hive.id}: $e');
      }
    }

    // Phase 2: Pull fresh remote data
    try {
      final remoteAudios =
          await _remoteDatasource.getAudiosByUploader(''); // uses /audio/my-files
      final remoteIds = <String>{};

      for (final remote in remoteAudios) {
        remoteIds.add(remote.id!);
        final existing = await _localDatasource.getAudioById(remote.id!);
        // Only overwrite if local copy is synced (no pending changes)
        if (existing == null || existing.syncStatus == 0) {
          final hiveModel = remote.toHiveModel().copyWith(
            localPath: existing?.localPath ?? '',
            title: existing?.title, // preserve user-set title
          );
          await _localDatasource.saveAudio(hiveModel);
        }
      }

      debugPrint('[AudioSync] Pulled ${remoteAudios.length} remote audios');
    } catch (e) {
      debugPrint('[AudioSync] Failed to pull remote audios: $e');
    }

    debugPrint('[AudioSync] Sync complete');
  }
}

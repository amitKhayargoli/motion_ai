import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
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
  }) : _localDatasource = localDatasource,
       _remoteDatasource = remoteDatasource,
       _networkInfo = networkInfo;

  @override
  Future<Either<Failure, AudioFileEntity>> saveAudio(
    AudioFileEntity audio,
  ) async {
    try {
      await _localDatasource.saveAudio(audio.toHiveModel());
      return Right(audio);
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
      );

      final updatedAudio = audio.copyWith(cloudUrl: apiModel.cloudUrl);

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

      // 2. Success? Update Hive so they are available offline next time
      await _localDatasource.cacheAudios(remoteAudios);

      return Right(remoteAudios.map((model) => model.toEntity()).toList());
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
  Future<Either<Failure, bool>> deleteAudio(String audioId) async {
    try {
      await _localDatasource.deleteAudio(audioId);

      // Optional: remote delete later
      // await _remoteDatasource.deleteAudio(audioId);

      return const Right(true);
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }
}

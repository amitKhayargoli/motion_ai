import '../entities/audio_file_entity.dart';

import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';

abstract interface class IAudioFileRepository {
  Future<Either<Failure, List<AudioFileEntity>>> getUserAudioFiles(
    String userId,
  );

  Future<Either<Failure, AudioFileEntity>> saveAudio(AudioFileEntity audio);
  Future<Either<Failure, AudioFileEntity>> uploadAudio(AudioFileEntity audio);
  Future<Either<Failure, AudioFileEntity>> updateAudio(String audioId,
      {String? title});
  Future<Either<Failure, bool>> deleteAudio(String audioId);

  /// Push pending local changes to the server, then pull fresh remote data
  Future<void> syncAudioFiles();
}

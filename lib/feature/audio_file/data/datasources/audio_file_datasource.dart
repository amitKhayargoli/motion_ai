import 'package:motion_ai/feature/audio_file/data/models/audio_file_api_model.dart';
import 'package:motion_ai/feature/audio_file/data/models/audio_file_hive_model.dart';

abstract class IAudioLocalDatasource {
  Future<void> saveAudio(AudioFileHiveModel audio);
  List<AudioFileHiveModel> getAudiosByUploader(String uploaderId);
  Future<AudioFileHiveModel?> getAudioById(String audioId);
  Future<void> deleteAudio(String audioId);
  Future<void> cacheAudios(List<AudioFileApiModel> audios);
  Future<List<AudioFileHiveModel>> getStoredAudios();
  Future<List<AudioFileHiveModel>> getPendingAudios();
  Future<void> clearAll();
}

abstract class IAudioRemoteDatasource {
  Future<AudioFileApiModel> uploadAudio({
    required String filePath,
    required int durationSeconds,
    String? title,
  });
  Future<List<AudioFileApiModel>> getAudiosByUploader(String userId);
  Future<List<AudioFileApiModel>> getMyAudioFiles();
  Future<void> updateAudio(String audioId, {String? title});
  Future<void> deleteAudio(String audioId);
}

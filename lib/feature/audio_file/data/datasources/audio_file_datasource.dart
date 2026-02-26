import 'package:hive/hive.dart';
import 'package:motion_ai/feature/audio_file/data/models/audio_file_api_model.dart';
import 'package:motion_ai/feature/audio_file/data/models/audio_file_hive_model.dart';

abstract class IAudioLocalDatasource {
  Future<void> saveAudio(AudioFileHiveModel audio);
  List<AudioFileHiveModel> getAudiosByUploader(String uploaderId);
  Future<void> deleteAudio(String audioId);
  Future<void> cacheAudios(List<AudioFileApiModel> audios);
  Future<List<AudioFileHiveModel>> getStoredAudios();
}

abstract class IAudioRemoteDatasource {
  Future<AudioFileApiModel> uploadAudio({
    required String filePath,
    required int durationSeconds,
  });
  Future<List<AudioFileApiModel>> getAudiosByUploader(String userId);
}

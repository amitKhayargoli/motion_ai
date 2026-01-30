import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/services/hive/hive_service.dart';
import 'package:motion_ai/feature/audio_file/data/datasources/audio_file_datasource.dart';
import 'package:motion_ai/feature/audio_file/data/models/audio_file_api_model.dart';
import 'package:motion_ai/feature/audio_file/data/models/audio_file_hive_model.dart';

// Provider
final audioLocalDatasourceProvider = Provider<IAudioLocalDatasource>((ref) {
  final hiveService = ref.read(hiveServiceProvider);
  return AudioLocalDatasource(hiveService: hiveService);
});

class AudioLocalDatasource implements IAudioLocalDatasource {
  final HiveService _hiveService;

  AudioLocalDatasource({required HiveService hiveService})
    : _hiveService = hiveService;

  @override
  Future<void> saveAudio(AudioFileHiveModel audio) async {
    await _hiveService.saveAudio(audio);
  }

  @override
  List<AudioFileHiveModel> getAudiosByUploader(String uploaderId) {
    return _hiveService.getAudiosByUploader(uploaderId);
  }

  @override
  Future<void> deleteAudio(String audioId) async {
    await _hiveService.deleteAudio(audioId);
  }

  @override
  Future<void> cacheAudios(List<AudioFileApiModel> audios) async {
    for (final apiModel in audios) {
      // Assuming AudioFileApiModel has toHiveModel()
      await saveAudio(apiModel.toHiveModel());
    }
  }

  @override
  Future<List<AudioFileHiveModel>> getStoredAudios() async {
    // Assuming this returns all stored audios; adjust if needed
    return _hiveService
        .getStoredAudios(); // Or implement separately if getAudios is sync
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/core/services/hive/hive_service.dart';
import 'package:motion_ai/feature/audio_file/data/datasources/audio_file_datasource.dart';
import 'package:motion_ai/feature/audio_file/data/models/audio_file_api_model.dart';
import 'package:motion_ai/feature/audio_file/data/models/audio_file_hive_model.dart';

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
  Future<AudioFileHiveModel?> getAudioById(String audioId) async {
    return _hiveService.getAudioById(audioId);
  }

  @override
  Future<void> deleteAudio(String audioId) async {
    await _hiveService.deleteAudio(audioId);
  }

  @override
  Future<void> cacheAudios(List<AudioFileApiModel> audios) async {
    for (final apiModel in audios) {
      await saveAudio(apiModel.toHiveModel());
    }
  }

  @override
  Future<List<AudioFileHiveModel>> getStoredAudios() async {
    return _hiveService.getStoredAudios();
  }

  @override
  Future<List<AudioFileHiveModel>> getPendingAudios() async {
    return _hiveService.getPendingAudios();
  }

  @override
  Future<void> clearAll() async {
    await _hiveService.clearAudioFiles();
  }
}

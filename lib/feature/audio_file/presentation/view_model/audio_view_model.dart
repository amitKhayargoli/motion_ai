import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/core/services/storage/user_session_service.dart';
import 'package:motion_ai/core/sync/audio_auto_sync.dart';
import 'package:motion_ai/feature/audio_file/data/datasources/audio_file_datasource.dart';
import 'package:motion_ai/feature/audio_file/domain/entities/audio_file_entity.dart';
import 'package:motion_ai/feature/audio_file/domain/usecases/delete_audio_usecase.dart';
import 'package:motion_ai/feature/audio_file/domain/usecases/get_audios_usecase.dart';
import 'package:motion_ai/feature/audio_file/domain/usecases/update_audio_usecase.dart';
import 'package:motion_ai/feature/audio_file/domain/usecases/upload_audio_usecase.dart';
import 'package:motion_ai/feature/audio_file/presentation/state/audio_state.dart';
import 'package:uuid/uuid.dart';

final audioViewModelProvider = NotifierProvider<AudioViewModel, AudioState>(
  AudioViewModel.new,
);

class AudioViewModel extends Notifier<AudioState> {
  late final UploadAudioUsecase _uploadAudioUsecase;
  late final GetAudiosUsecase _getAudiosUsecase;
  late final UpdateAudioUsecase _updateAudioUsecase;
  late final DeleteAudioUsecase _deleteAudioUsecase;
  late final IAudioLocalDatasource _localSource;
  late final UserSessionService _userSessionService;

  @override
  AudioState build() {
    _uploadAudioUsecase = ref.read(uploadAudioUsecaseProvider);
    _getAudiosUsecase = ref.read(getAudiosUsecaseProvider);
    _updateAudioUsecase = ref.read(updateAudioUsecaseProvider);
    _deleteAudioUsecase = ref.read(deleteAudioUsecaseProvider);
    _localSource = ref.read(audioLocalDatasourceProvider);
    _userSessionService = ref.read(userSessionServiceProvider);

    Future.microtask(() => loadInitialData());

    return const AudioState(status: AudioStatus.initial);
  }

  /// Local-First: load from Hive first, then sync remote
  Future<void> loadInitialData() async {
    try {
      final localModels = await _localSource.getStoredAudios();
      final localEntities =
          localModels.map((m) => AudioFileEntity.fromHiveModel(m)).toList();

      if (localEntities.isNotEmpty) {
        state = state.copyWith(
          audios: localEntities,
          status: AudioStatus.success,
        );
      } else {
        state = state.copyWith(status: AudioStatus.loading);
      }
    } catch (e) {
      debugPrint("Error loading from Hive: $e");
    }

    await fetchAudios();
  }

  /// Remote Fetching (MongoDB)
  Future<void> fetchAudios() async {
    if (state.audios == null || state.audios!.isEmpty) {
      state = state.copyWith(status: AudioStatus.loading);
    }

    final userId = _userSessionService.getUserId() ?? 'local_user';
    final result = await _getAudiosUsecase(GetAudiosParams(userId: userId));

    result.fold(
      (failure) {
        state = state.copyWith(
          status:
              state.audios != null ? AudioStatus.success : AudioStatus.error,
          errorMessage: state.audios != null ? null : failure.message,
        );
      },
      (audioEntities) {
        state = state.copyWith(
          status: AudioStatus.success,
          audios: audioEntities,
        );
      },
    );
  }

  Future<void> uploadAudio({
    required String filePath,
    required int durationSeconds,
    String? title,
    String? fileName,
  }) async {
    state = state.copyWith(status: AudioStatus.loading);

    final result = await _uploadAudioUsecase(
      UploadAudioParams(
        filePath: filePath,
        durationSeconds: durationSeconds,
        title: title,
        fileName: fileName,
      ),
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: AudioStatus.error,
        errorMessage: failure.message,
      ),
      (audioEntity) {
        state = state.copyWith(status: AudioStatus.success);
        fetchAudios();
      },
    );
  }

  /// Save a recording locally with a fileName, then queue background upload
  Future<void> saveRecording({
    required String filePath,
    required int durationSeconds,
    required String fileName,
  }) async {
    final userId = _userSessionService.getUserId() ?? 'local_user';
    final now = DateTime.now();
    final id = const Uuid().v4();

    final entity = AudioFileEntity(
      id: id,
      title: fileName, // use fileName as the display title
      fileName: fileName,
      localPath: filePath,
      durationSeconds: durationSeconds,
      mimeType: 'audio/aac',
      uploadedAt: now,
      uploaderId: userId,
      username: '',
      syncStatus: 1, // pendingUpload
    );

    // Optimistic: add to state immediately
    final currentAudios = List<AudioFileEntity>.from(state.audios ?? []);
    currentAudios.insert(0, entity);
    state = state.copyWith(
      audios: currentAudios,
      status: AudioStatus.success,
    );

    // Save locally in Hive (repository marks syncStatus = 1)
    await _localSource.saveAudio(entity.toHiveModel());

    // Sync will pick up pendingUpload entries and upload to remote
    ref.read(audioAutoSyncProvider.notifier).trySync();
  }

  /// Update audio title (optimistic)
  Future<void> updateAudio({
    required String audioId,
    String? title,
  }) async {
    final currentAudios = List<AudioFileEntity>.from(state.audios ?? []);
    final index = currentAudios.indexWhere((a) => a.id == audioId);
    if (index == -1) return;

    final updated = currentAudios[index].copyWith(title: title);
    currentAudios[index] = updated;
    state = state.copyWith(audios: currentAudios);

    await _updateAudioUsecase(
      UpdateAudioParams(audioId: audioId, title: title),
    );

    // Trigger sync in case we're offline and it got queued
    ref.read(audioAutoSyncProvider.notifier).trySync();
  }

  /// Delete audio (optimistic)
  Future<void> deleteAudio(String audioId) async {
    final currentAudios = List<AudioFileEntity>.from(state.audios ?? []);
    currentAudios.removeWhere((a) => a.id == audioId);
    state = state.copyWith(audios: currentAudios);

    await _deleteAudioUsecase(DeleteAudioParams(audioId: audioId));
  }

  /// Delete multiple audios (optimistic)
  Future<void> deleteMultipleAudios(List<String> audioIds) async {
    final currentAudios = List<AudioFileEntity>.from(state.audios ?? []);
    currentAudios.removeWhere((a) => audioIds.contains(a.id));
    state = state.copyWith(audios: currentAudios);

    for (final id in audioIds) {
      await _deleteAudioUsecase(DeleteAudioParams(audioId: id));
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Called on logout — wipes Hive cache and resets in-memory state
  Future<void> clearAudios() async {
    await _localSource.clearAll();
    state = const AudioState(status: AudioStatus.initial);
  }

  /// Reload audios from Hive (call after sync completes to refresh UI)
  Future<void> reloadFromLocal() async {
    try {
      final localModels = await _localSource.getStoredAudios();
      final localEntities =
          localModels.map((m) => AudioFileEntity.fromHiveModel(m)).toList();
      state = state.copyWith(
        audios: localEntities,
        status: AudioStatus.success,
      );
    } catch (e) {
      debugPrint("Error reloading from Hive: $e");
    }
  }
}

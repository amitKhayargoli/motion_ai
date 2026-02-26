import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/core/services/storage/user_session_service.dart';
import 'package:motion_ai/feature/audio_file/data/datasources/audio_file_datasource.dart';
import 'package:motion_ai/feature/audio_file/domain/entities/audio_file_entity.dart';
import 'package:motion_ai/feature/audio_file/domain/usecases/get_audios_usecase.dart';
import 'package:motion_ai/feature/audio_file/domain/usecases/upload_audio_usecase.dart';
import 'package:motion_ai/feature/audio_file/presentation/state/audio_state.dart';

final audioViewModelProvider = NotifierProvider<AudioViewModel, AudioState>(
  AudioViewModel.new,
);

class AudioViewModel extends Notifier<AudioState> {
  late final UploadAudioUsecase _uploadAudioUsecase;
  late final GetAudiosUsecase _getAudiosUsecase;
  late final IAudioLocalDatasource _localSource;
  late final UserSessionService _userSessionService;

  @override
  AudioState build() {
    _uploadAudioUsecase = ref.read(uploadAudioUsecaseProvider);
    _getAudiosUsecase = ref.read(getAudiosUsecaseProvider);
    _localSource = ref.read(audioLocalDatasourceProvider);
    _userSessionService = ref.read(userSessionServiceProvider);

    // Trigger the initial load logic
    // We use Future.microtask to ensure the UI can finish building the first frame
    Future.microtask(() => loadInitialData());

    // Initialize state with 'initial' status and null/empty audios
    return const AudioState(status: AudioStatus.initial);
  }

  /// 1. The Local-First Logic
  Future<void> loadInitialData() async {
    // A. Immediately load from Hive to stop the spinner
    try {
      final localModels = await _localSource.getStoredAudios();
      final localEntities = localModels
          .map((m) => AudioFileEntity.fromHiveModel(m))
          .toList(); // Fixed: Use fromHiveModel

      if (localEntities.isNotEmpty) {
        state = state.copyWith(
          audios: localEntities,
          status: AudioStatus.success, // Data found, UI can render now!
        );
      } else {
        state = state.copyWith(status: AudioStatus.loading);
      }
    } catch (e) {
      debugPrint("Error loading from Hive: $e");
    }

    // B. Now sync with MongoDB in the background
    await fetchAudios();
  }

  /// 2. Remote Fetching (MongoDB)
  Future<void> fetchAudios() async {
    // Only show full loading if we don't already have local data
    if (state.audios == null || state.audios!.isEmpty) {
      state = state.copyWith(status: AudioStatus.loading);
    }

    final userId = _userSessionService.getUserId() ?? 'local_user';
    final result = await _getAudiosUsecase(GetAudiosParams(userId: userId));

    result.fold(
      (failure) {
        // If MongoDB fails/timeouts, we keep the Hive data
        state = state.copyWith(
          status: state.audios != null
              ? AudioStatus.success
              : AudioStatus.error,
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
  }) async {
    state = state.copyWith(status: AudioStatus.loading);

    final result = await _uploadAudioUsecase(
      UploadAudioParams(filePath: filePath, durationSeconds: durationSeconds),
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: AudioStatus.error,
        errorMessage: failure.message,
      ),
      (audioEntity) {
        state = state.copyWith(status: AudioStatus.success);
        // Refresh list after successful upload
        fetchAudios();
      },
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

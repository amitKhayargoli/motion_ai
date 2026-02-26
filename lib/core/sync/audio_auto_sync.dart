import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/services/connectivity/network_info.dart';
import 'package:motion_ai/feature/audio_file/data/repositories/audio_file_repository.dart';
import 'package:motion_ai/feature/audio_file/presentation/view_model/audio_view_model.dart';

class AudioSyncState {
  final bool isSyncing;
  final DateTime? lastSuccessAt;
  final String? lastError;

  const AudioSyncState({
    required this.isSyncing,
    this.lastSuccessAt,
    this.lastError,
  });

  AudioSyncState copyWith({
    bool? isSyncing,
    DateTime? lastSuccessAt,
    String? lastError,
  }) {
    return AudioSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastError: lastError,
    );
  }

  static const idle = AudioSyncState(isSyncing: false);
}

final audioAutoSyncProvider =
    NotifierProvider<AudioAutoSyncNotifier, AudioSyncState>(
  AudioAutoSyncNotifier.new,
);

class AudioAutoSyncNotifier extends Notifier<AudioSyncState> {
  bool _running = false;

  @override
  AudioSyncState build() => AudioSyncState.idle;

  Future<void> trySync() async {
    if (_running) return;
    _running = true;
    state = state.copyWith(isSyncing: true, lastError: null);

    try {
      final ok = await ref.read(networkInfoProvider).isConnected;
      if (!ok) return;

      await ref.read(audioFileRepositoryProvider).syncAudioFiles();

      // Refresh the viewmodel's in-memory list from Hive
      await ref.read(audioViewModelProvider.notifier).reloadFromLocal();

      state = state.copyWith(
        lastSuccessAt: DateTime.now(),
        isSyncing: false,
        lastError: null,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
    } finally {
      _running = false;
      if (state.isSyncing) {
        state = state.copyWith(isSyncing: false);
      }
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/feature/notes/data/providers/note_repository_provider.dart';
import 'package:motion_ai/feature/notes/domain/usecases/get_transcript_usecase.dart';
import 'package:motion_ai/feature/notes/domain/usecases/transcribe_audio_usecase.dart';
import 'package:motion_ai/feature/notes/presentation/state/transcript_state.dart';

final getTranscriptUseCaseProvider =
    Provider<GetTranscriptByAudioFileIdUseCase>((ref) {
  return GetTranscriptByAudioFileIdUseCase(ref.read(noteRepositoryProvider));
});

final transcribeAudioUseCaseProvider = Provider<TranscribeAudioUseCase>((ref) {
  return TranscribeAudioUseCase(ref.read(noteRepositoryProvider));
});

final transcriptViewModelProvider =
    NotifierProvider.autoDispose<TranscriptViewModel, TranscriptState>(
        TranscriptViewModel.new);

class TranscriptViewModel extends Notifier<TranscriptState> {
  @override
  TranscriptState build() => TranscriptState.initial();

  Future<void> fetchTranscript(String audioFileId) async {
    state = TranscriptState.initial().copyWith(
      status: TranscriptStatus.loading,
    );
    final usecase = ref.read(getTranscriptUseCaseProvider);
    final res = await usecase(GetTranscriptParams(audioFileId));

    res.fold(
      (f) => state =
          state.copyWith(status: TranscriptStatus.error, error: f.message),
      (note) =>
          state = state.copyWith(status: TranscriptStatus.loaded, note: note),
    );
  }

  Future<bool> transcribeAudio({
    required String audioFileId,
    required String workspaceId,
    String? noteTitle,
  }) async {
    state = state.copyWith(status: TranscriptStatus.loading, clearError: true);

    final usecase = ref.read(transcribeAudioUseCaseProvider);
    final res = await usecase(TranscribeAudioParams(
      audioFileId: audioFileId,
      workspaceId: workspaceId,
      noteTitle: noteTitle,
    ));

    return res.fold(
      (f) {
        state =
            state.copyWith(status: TranscriptStatus.error, error: f.message);
        return false;
      },
      (note) {
        state = state.copyWith(status: TranscriptStatus.loaded, note: note);
        return true;
      },
    );
  }
}

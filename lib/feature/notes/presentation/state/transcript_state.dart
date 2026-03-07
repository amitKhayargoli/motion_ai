// feature/transcript/presentation/state/transcript_state.dart
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';

enum TranscriptStatus { initial, loading, loaded, error }

class TranscriptState {
  final TranscriptStatus status;
  final NoteEntity? note;
  final String? error;

  const TranscriptState({
    required this.status,
    required this.note,
    required this.error,
  });

  factory TranscriptState.initial() => const TranscriptState(
        status: TranscriptStatus.initial,
        note: null,
        error: null,
      );

  TranscriptState copyWith({
    TranscriptStatus? status,
    NoteEntity? note,
    String? error,
    bool clearError = false,
  }) {
    return TranscriptState(
      status: status ?? this.status,
      note: note ?? this.note,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

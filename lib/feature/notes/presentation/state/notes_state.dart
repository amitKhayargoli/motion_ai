import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';

enum NotesStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  error,
}

class NotesState {
  final NotesStatus status;
  final String? error;
  final String? workspaceId; // currently loaded workspace
  final List<NoteEntity> notes;

  const NotesState({
    required this.status,
    required this.notes,
    required this.workspaceId,
    required this.error,
  });

  factory NotesState.initial() => const NotesState(
    status: NotesStatus.initial,
    notes: [],
    workspaceId: null,
    error: null,
  );

  NotesState copyWith({
    NotesStatus? status,
    String? workspaceId,
    List<NoteEntity>? notes,
    String? error,
    bool clearError = false,
  }) {
    return NotesState(
      status: status ?? this.status,
      workspaceId: workspaceId ?? this.workspaceId,
      notes: notes ?? this.notes,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

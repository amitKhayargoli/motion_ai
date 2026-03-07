import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/domain/usecases/create_notes_usecase.dart';
import 'package:motion_ai/feature/notes/domain/usecases/delete_note_usecase.dart';
import 'package:motion_ai/feature/notes/domain/usecases/get_workspace_notes_usecase.dart';
import 'package:motion_ai/feature/notes/domain/usecases/update_note_usecase.dart';
import 'package:motion_ai/feature/notes/presentation/providers/notes_providers.dart';

import 'package:motion_ai/feature/notes/presentation/state/notes_state.dart';

final notesViewModelProvider = NotifierProvider<NotesViewModel, NotesState>(
  NotesViewModel.new,
);

class NotesViewModel extends Notifier<NotesState> {
  @override
  NotesState build() => NotesState.initial();

  // ===== Helpers
  void clearError() => state = state.copyWith(clearError: true);

  // ===== Fetch workspace notes (local only, fast)
  Future<bool> fetchWorkspaceNotes(String workspaceId) async {
    // Avoid refetching same workspace unnecessarily
    if (state.workspaceId == workspaceId &&
        state.status == NotesStatus.loaded) {
      return true;
    }

    state = state.copyWith(
      status: NotesStatus.loading,
      workspaceId: workspaceId,
      clearError: true,
    );

    final usecase = ref.read(getWorkspaceNotesUseCaseProvider);
    final res = await usecase(GetWorkspaceNotesParams(workspaceId));

    return res.fold(
      (f) {
        state = state.copyWith(status: NotesStatus.error, error: f.message);
        return false;
      },
      (list) {
        // newest first (optional)
        final sorted = [...list]..sort((a, b) {
            final ad = a.updatedAt ?? a.createdAt ?? DateTime(0);
            final bd = b.updatedAt ?? b.createdAt ?? DateTime(0);
            return bd.compareTo(ad);
          });

        state = state.copyWith(
          status: NotesStatus.loaded,
          notes: sorted,
          workspaceId: workspaceId,
        );
        return true;
      },
    );
  }

  // ===== Refresh workspace notes (pulls from remote, then returns local)
  Future<bool> refreshWorkspaceNotes(String workspaceId) async {
    state = state.copyWith(
      status: NotesStatus.loading,
      workspaceId: workspaceId,
      clearError: true,
    );

    final usecase = ref.read(getWorkspaceNotesUseCaseProvider);
    final res = await usecase(
      GetWorkspaceNotesParams(workspaceId, forceRefresh: true),
    );

    return res.fold(
      (f) {
        state = state.copyWith(status: NotesStatus.error, error: f.message);
        return false;
      },
      (list) {
        final sorted = [...list]..sort((a, b) {
            final ad = a.updatedAt ?? a.createdAt ?? DateTime(0);
            final bd = b.updatedAt ?? b.createdAt ?? DateTime(0);
            return bd.compareTo(ad);
          });

        state = state.copyWith(
          status: NotesStatus.loaded,
          notes: sorted,
          workspaceId: workspaceId,
        );
        return true;
      },
    );
  }

  // ===== Create note
  Future<NoteEntity?> createNote({
    required String workspaceId,
    required String title,
    required String content,
  }) async {
    state = state.copyWith(status: NotesStatus.creating, clearError: true);

    final usecase = ref.read(createNoteUseCaseProvider);
    final res = await usecase(
      CreateNoteParams(
        workspaceId: workspaceId,
        title: title,
        content: content,
      ),
    );

    return res.fold(
      (f) {
        state = state.copyWith(status: NotesStatus.error, error: f.message);
        return null;
      },
      (note) {
        final updated = [note, ...state.notes];
        state = state.copyWith(
          status: NotesStatus.loaded,
          notes: updated,
          workspaceId: workspaceId,
        );
        return note;
      },
    );
  }

  // ===== Update note
  Future<NoteEntity?> updateNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    state = state.copyWith(status: NotesStatus.updating, clearError: true);

    final usecase = ref.read(updateNoteUseCaseProvider);
    final res = await usecase(
      UpdateNoteParams(noteId: noteId, title: title, content: content),
    );

    return res.fold(
      (f) {
        state = state.copyWith(status: NotesStatus.error, error: f.message);
        return null;
      },
      (updatedNote) {
        final updatedList = state.notes
            .map((n) => n.id == updatedNote.id ? updatedNote : n)
            .toList();

        state = state.copyWith(status: NotesStatus.loaded, notes: updatedList);
        return updatedNote;
      },
    );
  }

  // ===== Delete note
  Future<bool> deleteNote(String noteId) async {
    state = state.copyWith(status: NotesStatus.deleting, clearError: true);

    final usecase = ref.read(deleteNoteUseCaseProvider);
    final res = await usecase(DeleteNoteParams(noteId));

    return res.fold(
      (f) {
        state = state.copyWith(status: NotesStatus.error, error: f.message);
        return false;
      },
      (_) {
        final updated = state.notes.where((n) => n.id != noteId).toList();
        state = state.copyWith(status: NotesStatus.loaded, notes: updated);
        return true;
      },
    );
  }
}

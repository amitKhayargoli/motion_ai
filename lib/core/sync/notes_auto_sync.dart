import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/services/connectivity/network_info.dart';
import 'package:motion_ai/feature/notes/data/providers/note_repository_provider.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';
import 'package:motion_ai/feature/notes/domain/repositories/notes_repository.dart';

class NotesSyncState {
  final bool isSyncing;
  final DateTime? lastSuccessAt;
  final String? lastError;

  const NotesSyncState({
    required this.isSyncing,
    this.lastSuccessAt,
    this.lastError,
  });

  NotesSyncState copyWith({
    bool? isSyncing,
    DateTime? lastSuccessAt,
    String? lastError,
  }) {
    return NotesSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastError: lastError,
    );
  }

  static const idle = NotesSyncState(isSyncing: false);
}

final notesAutoSyncProvider =
    NotifierProvider<NotesAutoSyncNotifier, NotesSyncState>(
  NotesAutoSyncNotifier.new,
);

class NotesAutoSyncNotifier extends Notifier<NotesSyncState> {
  bool _running = false;

  @override
  NotesSyncState build() => NotesSyncState.idle;

  Future<void> trySync() async {
    if (_running) return;
    _running = true;
    state = state.copyWith(isSyncing: true, lastError: null);

    try {
      final ok = await ref.read(networkInfoProvider).isConnected;
      if (!ok) return;

      final ws = ref.read(workspaceViewModelProvider).selected;
      if (ws == null) return;

      await ref.read(noteRepositoryProvider).syncWorkspaceNotes(ws.id);

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
      // ensure isSyncing false even on early returns
      if (state.isSyncing) {
        state = state.copyWith(isSyncing: false);
      }
    }
  }
}

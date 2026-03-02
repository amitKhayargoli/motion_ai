import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/services/connectivity/network_info.dart';
import 'package:motion_ai/feature/tasks/data/providers/task_repository_provider.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

class TasksSyncState {
  final bool isSyncing;
  final DateTime? lastSuccessAt;
  final String? lastError;

  const TasksSyncState({
    required this.isSyncing,
    this.lastSuccessAt,
    this.lastError,
  });

  TasksSyncState copyWith({
    bool? isSyncing,
    DateTime? lastSuccessAt,
    String? lastError,
  }) {
    return TasksSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastError: lastError,
    );
  }

  static const idle = TasksSyncState(isSyncing: false);
}

final tasksAutoSyncProvider =
    NotifierProvider<TasksAutoSyncNotifier, TasksSyncState>(
  TasksAutoSyncNotifier.new,
);

class TasksAutoSyncNotifier extends Notifier<TasksSyncState> {
  bool _running = false;

  @override
  TasksSyncState build() => TasksSyncState.idle;

  Future<void> trySync() async {
    if (_running) return;
    _running = true;
    state = state.copyWith(isSyncing: true, lastError: null);

    try {
      final ok = await ref.read(networkInfoProvider).isConnected;
      if (!ok) return;

      final ws = ref.read(workspaceViewModelProvider).selected;
      if (ws == null) return;

      await ref.read(taskRepositoryProvider).syncWorkspaceTasks(ws.id);

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

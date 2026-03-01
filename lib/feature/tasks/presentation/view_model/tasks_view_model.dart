import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/feature/tasks/domain/entities/task_entity.dart';
import 'package:motion_ai/feature/tasks/domain/usecases/create_task_usecase.dart';
import 'package:motion_ai/feature/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:motion_ai/feature/tasks/domain/usecases/get_workspace_tasks_usecase.dart';
import 'package:motion_ai/feature/tasks/domain/usecases/update_task_usecase.dart';
import 'package:motion_ai/feature/tasks/presentation/providers/tasks_providers.dart';
import 'package:motion_ai/feature/tasks/presentation/state/tasks_state.dart';

final tasksViewModelProvider = NotifierProvider<TasksViewModel, TasksState>(
  TasksViewModel.new,
);

class TasksViewModel extends Notifier<TasksState> {
  @override
  TasksState build() => TasksState.initial();

  void clearError() => state = state.copyWith(clearError: true);

  // ===== Fetch workspace tasks (local only, fast)
  Future<bool> fetchWorkspaceTasks(String workspaceId) async {
    // Only show loading spinner when workspace changes or first load;
    // when re-reading after sync, keep the current list visible.
    if (state.workspaceId != workspaceId ||
        state.status != TasksStatus.loaded) {
      state = state.copyWith(
        status: TasksStatus.loading,
        workspaceId: workspaceId,
        clearError: true,
      );
    }

    final usecase = ref.read(getWorkspaceTasksUseCaseProvider);
    final res = await usecase(GetWorkspaceTasksParams(workspaceId));

    return res.fold(
      (f) {
        state = state.copyWith(status: TasksStatus.error, error: f.message);
        return false;
      },
      (list) {
        final sorted = [...list]..sort((a, b) {
            final ad = a.updatedAt ?? a.createdAt ?? DateTime(0);
            final bd = b.updatedAt ?? b.createdAt ?? DateTime(0);
            return bd.compareTo(ad);
          });

        state = state.copyWith(
          status: TasksStatus.loaded,
          tasks: sorted,
          workspaceId: workspaceId,
        );
        return true;
      },
    );
  }

  // ===== Refresh workspace tasks (pulls from remote, then returns local)
  Future<bool> refreshWorkspaceTasks(String workspaceId) async {
    state = state.copyWith(
      status: TasksStatus.loading,
      workspaceId: workspaceId,
      clearError: true,
    );

    final usecase = ref.read(getWorkspaceTasksUseCaseProvider);
    final res = await usecase(
      GetWorkspaceTasksParams(workspaceId, forceRefresh: true),
    );

    return res.fold(
      (f) {
        state = state.copyWith(status: TasksStatus.error, error: f.message);
        return false;
      },
      (list) {
        final sorted = [...list]..sort((a, b) {
            final ad = a.updatedAt ?? a.createdAt ?? DateTime(0);
            final bd = b.updatedAt ?? b.createdAt ?? DateTime(0);
            return bd.compareTo(ad);
          });

        state = state.copyWith(
          status: TasksStatus.loaded,
          tasks: sorted,
          workspaceId: workspaceId,
        );
        return true;
      },
    );
  }

  // ===== Create task
  Future<TaskEntity?> createTask({
    required String workspaceId,
    required String title,
    String? description,
    String? priority,
    DateTime? dueDate,
  }) async {
    state = state.copyWith(status: TasksStatus.creating, clearError: true);

    final usecase = ref.read(createTaskUseCaseProvider);
    final res = await usecase(
      CreateTaskParams(
        workspaceId: workspaceId,
        title: title,
        description: description,
        priority: priority,
        dueDate: dueDate,
      ),
    );

    return res.fold(
      (f) {
        state = state.copyWith(status: TasksStatus.error, error: f.message);
        return null;
      },
      (task) {
        final updated = [task, ...state.tasks];
        state = state.copyWith(
          status: TasksStatus.loaded,
          tasks: updated,
          workspaceId: workspaceId,
        );
        return task;
      },
    );
  }

  // ===== Update task (optimistic – UI updates instantly)
  Future<TaskEntity?> updateTask({
    required String taskId,
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    DateTime? dueDate,
  }) async {
    // 1. Apply optimistic update to UI state immediately
    final index = state.tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return null;

    final existing = state.tasks[index];
    final optimistic = existing.copyWith(
      title: title,
      description: description,
      isCompleted: isCompleted,
      priority: priority,
      dueDate: dueDate,
      updatedAt: DateTime.now(),
    );

    final optimisticList = [...state.tasks];
    optimisticList[index] = optimistic;
    state = state.copyWith(tasks: optimisticList);

    // 2. Fire use case in background (Hive write + remote sync)
    _syncUpdateInBackground(
      taskId,
      title: title,
      description: description,
      isCompleted: isCompleted,
      priority: priority,
      dueDate: dueDate,
    );

    return optimistic;
  }

  void _syncUpdateInBackground(
    String taskId, {
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    DateTime? dueDate,
  }) {
    final usecase = ref.read(updateTaskUseCaseProvider);
    usecase(
      UpdateTaskParams(
        taskId: taskId,
        title: title,
        description: description,
        isCompleted: isCompleted,
        priority: priority,
        dueDate: dueDate,
      ),
    ).then((res) {
      res.fold(
        (_) {
          // Local write succeeded (repository is local-first),
          // remote might have failed – task stays with pendingUpdate syncStatus
          // and will be retried on next sync/refresh.
        },
        (serverTask) {
          // Silently update with server response (e.g. server timestamps)
          final currentList = state.tasks;
          final idx = currentList.indexWhere(
            (t) => t.id == serverTask.id || t.id == taskId,
          );
          if (idx != -1) {
            final updated = [...currentList];
            updated[idx] = serverTask;
            state = state.copyWith(tasks: updated);
          }
        },
      );
    });
  }

  // ===== Delete task (optimistic – UI updates instantly)
  Future<bool> deleteTask(String taskId) async {
    // 1. Apply optimistic removal from UI state immediately
    final optimisticList = state.tasks.where((t) => t.id != taskId).toList();
    state = state.copyWith(tasks: optimisticList);

    // 2. Fire use case in background (Hive delete + remote sync)
    _syncDeleteInBackground(taskId);

    return true;
  }

  void _syncDeleteInBackground(String taskId) {
    final usecase = ref.read(deleteTaskUseCaseProvider);
    usecase(DeleteTaskParams(taskId)).then((res) {
      res.fold(
        (f) {
          // Deletion failed at local level – this is unlikely since
          // the repository is local-first. If it happens, we could
          // re-fetch, but in practice this won't occur.
        },
        (_) {
          // Success – task is gone from local + queued for remote delete
        },
      );
    });
  }
}

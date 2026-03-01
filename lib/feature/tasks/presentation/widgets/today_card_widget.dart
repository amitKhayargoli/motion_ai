import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/sync/tasks_auto_sync.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/task_item_widget.dart';
import 'package:motion_ai/feature/tasks/presentation/pages/tasks_view.dart';
import 'package:motion_ai/feature/tasks/presentation/view_model/tasks_view_model.dart';
import 'package:motion_ai/feature/tasks/presentation/state/tasks_state.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';
import 'package:intl/intl.dart';

class TodayCardWidget extends ConsumerStatefulWidget {
  const TodayCardWidget({super.key});

  @override
  ConsumerState<TodayCardWidget> createState() => _TodayCardWidgetState();
}

class _TodayCardWidgetState extends ConsumerState<TodayCardWidget> {
  ProviderSubscription<TasksSyncState>? _syncSub;
  ProviderSubscription? _wsSub;

  @override
  void initState() {
    super.initState();

    // Listen to tasks auto-sync: when sync finishes, re-read local data
    _syncSub = ref.listenManual(tasksAutoSyncProvider, (prev, next) {
      final wasSyncing = prev?.isSyncing ?? false;

      if (wasSyncing && !next.isSyncing && next.lastError == null) {
        final ws = ref.read(workspaceViewModelProvider).selected;
        if (ws != null) {
          ref.read(tasksViewModelProvider.notifier).fetchWorkspaceTasks(ws.id);
        }
      }
    });

    // Re-fetch tasks when the active workspace changes
    _wsSub = ref.listenManual(workspaceViewModelProvider, (prev, next) {
      final prevId = prev?.selected?.id;
      final nextId = next.selected?.id;

      if (nextId != null && nextId != prevId) {
        ref.read(tasksViewModelProvider.notifier).fetchWorkspaceTasks(nextId);
        ref.read(tasksAutoSyncProvider.notifier).trySync();
      }
    });

    // Fetch local data first, then trigger remote sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ws = ref.read(workspaceViewModelProvider).selected;
      if (ws != null) {
        ref.read(tasksViewModelProvider.notifier).fetchWorkspaceTasks(ws.id);
      }
      ref.read(tasksAutoSyncProvider.notifier).trySync();
    });
  }

  @override
  void dispose() {
    _syncSub?.close();
    _wsSub?.close();
    super.dispose();
  }

  void _navigateToTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TasksListView()),
    );
  }

  void _toggleTask(String taskId, bool currentlyCompleted) {
    ref.read(tasksViewModelProvider.notifier).updateTask(
          taskId: taskId,
          isCompleted: !currentlyCompleted,
        );
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksViewModelProvider);

    // Show up to 3 most recent tasks
    final displayTasks = tasksState.tasks.take(3).toList();

    return GestureDetector(
      onTap: _navigateToTasks,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd MMM EEEE')
                          .format(DateTime.now())
                          .toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'sf_pro',
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Today',
                      style: TextStyle(
                        fontFamily: 'play_fair_display',
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _navigateToTasks,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.arrow_outward,
                      color: Colors.black,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (tasksState.status == TasksStatus.loading &&
                tasksState.tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  ),
                ),
              )
            else if (displayTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No tasks yet. Tap to add one.',
                  style: TextStyle(
                    fontFamily: 'sf_pro',
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              )
            else
              ...List.generate(displayTasks.length, (index) {
                final task = displayTasks[index];
                return Padding(
                  padding: EdgeInsets.only(
                    top: index == 0 ? 0 : 10,
                  ),
                  child: TaskItemWidget(
                    task: task.title,
                    isCompleted: task.isCompleted,
                    onTap: () => _toggleTask(task.id, task.isCompleted),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

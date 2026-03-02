import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:motion_ai/core/sync/tasks_auto_sync.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/gradient_scaffold_widget.dart';
import 'package:motion_ai/feature/tasks/domain/entities/task_entity.dart';
import 'package:motion_ai/feature/tasks/presentation/view_model/tasks_view_model.dart';
import 'package:motion_ai/feature/tasks/presentation/state/tasks_state.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

class TasksListView extends ConsumerStatefulWidget {
  const TasksListView({super.key});

  @override
  ConsumerState<TasksListView> createState() => _TasksListViewState();
}

class _TasksListViewState extends ConsumerState<TasksListView> {
  ProviderSubscription? _wsSub;
  ProviderSubscription<TasksSyncState>? _syncSub;
  bool _showSynced = false;
  Timer? _syncedTimer;
  final Set<String> _selectedTaskIds = {};

  bool get _isSelectionMode => _selectedTaskIds.isNotEmpty;

  @override
  void initState() {
    super.initState();

    // Listen to tasks auto-sync: when sync finishes, re-read local Hive data
    _syncSub = ref.listenManual(tasksAutoSyncProvider, (prev, next) {
      final wasSyncing = prev?.isSyncing ?? false;

      if (wasSyncing && !next.isSyncing && next.lastError == null) {
        final ws = ref.read(workspaceViewModelProvider).selected;
        if (ws != null) {
          ref.read(tasksViewModelProvider.notifier).fetchWorkspaceTasks(ws.id);
        }

        // Show "Synced" pill briefly
        _syncedTimer?.cancel();
        setState(() => _showSynced = true);
        _syncedTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showSynced = false);
        });
      }
    });

    // Fetch local data first, then trigger remote sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsState = ref.read(workspaceViewModelProvider);
      final selected = wsState.selected;
      if (selected != null) {
        ref
            .read(tasksViewModelProvider.notifier)
            .fetchWorkspaceTasks(selected.id);
      }
      ref.read(tasksAutoSyncProvider.notifier).trySync();
    });

    _wsSub = ref.listenManual(workspaceViewModelProvider, (prev, next) {
      final prevId = prev?.selected?.id;
      final nextId = next.selected?.id;

      if (nextId != null && nextId != prevId) {
        ref.read(tasksViewModelProvider.notifier).fetchWorkspaceTasks(nextId);
      }
      ref.read(tasksAutoSyncProvider.notifier).trySync();
    });
  }

  @override
  void dispose() {
    _wsSub?.close();
    _syncSub?.close();
    _syncedTimer?.cancel();
    super.dispose();
  }

  // ─── Selection helpers ───

  void _toggleSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedTaskIds.clear());
  }

  // ─── Create task dialog ───

  Future<void> _showCreateTaskDialog() async {
    final ws = ref.read(workspaceViewModelProvider).selected;
    if (ws == null) return;

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedPriority = 'MEDIUM';

    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 600
        ? screenWidth * 0.92
        : screenWidth < 1024
            ? screenWidth * 0.6
            : screenWidth * 0.4;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E3A0F),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Task', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: const Color(0xFFAEFB2A),
                    decoration: InputDecoration(
                      hintText: 'Task title',
                      hintStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFAEFB2A)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: const Color(0xFFAEFB2A),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Description (optional)',
                      hintStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFAEFB2A)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Priority: ',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedPriority,
                        dropdownColor: const Color(0xFF1E3A0F),
                        style: const TextStyle(color: Colors.white),
                        items: ['LOW', 'MEDIUM', 'HIGH']
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedPriority = val);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create',
                  style: TextStyle(color: Color(0xFFAEFB2A))),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    if (titleCtrl.text.trim().isEmpty) return;

    await ref.read(tasksViewModelProvider.notifier).createTask(
          workspaceId: ws.id,
          title: titleCtrl.text.trim(),
          description:
              descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          priority: selectedPriority,
        );
  }

  // ─── Edit task dialog ───

  Future<void> _showEditTaskDialog(TaskEntity task) async {
    final titleCtrl = TextEditingController(text: task.title);
    final descCtrl = TextEditingController(text: task.description ?? '');
    String selectedPriority = task.priority ?? 'MEDIUM';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E3A0F),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Task', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: const Color(0xFFAEFB2A),
                  decoration: InputDecoration(
                    hintText: 'Task title',
                    hintStyle: const TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFAEFB2A)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: const Color(0xFFAEFB2A),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    hintStyle: const TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFAEFB2A)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Priority: ',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedPriority,
                      dropdownColor: const Color(0xFF1E3A0F),
                      style: const TextStyle(color: Colors.white),
                      items: ['LOW', 'MEDIUM', 'HIGH']
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedPriority = val);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save',
                  style: TextStyle(color: Color(0xFFAEFB2A))),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    if (titleCtrl.text.trim().isEmpty) return;

    final newTitle = titleCtrl.text.trim();
    final newDesc = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();

    await ref.read(tasksViewModelProvider.notifier).updateTask(
          taskId: task.id,
          title: newTitle != task.title ? newTitle : null,
          description: newDesc != task.description ? newDesc : null,
          priority: selectedPriority != task.priority ? selectedPriority : null,
        );
  }

  // ─── Delete (single or bulk) ───

  Future<void> _confirmAndDeleteTasks(List<String> taskIds) async {
    final count = taskIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A0F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete ${count == 1 ? 'Task' : '$count Tasks'}?',
          style: const TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
        ),
        content: Text(
          count == 1
              ? 'This task will be permanently deleted.'
              : 'These $count tasks will be permanently deleted.',
          style: const TextStyle(color: Colors.white70, fontFamily: 'sf_pro'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70, fontFamily: 'sf_pro')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style:
                    TextStyle(color: Colors.redAccent, fontFamily: 'sf_pro')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    for (final id in taskIds) {
      await ref.read(tasksViewModelProvider.notifier).deleteTask(id);
    }

    _clearSelection();
  }

  void _toggleTaskCompletion(TaskEntity task) {
    ref.read(tasksViewModelProvider.notifier).updateTask(
          taskId: task.id,
          isCompleted: !task.isCompleted,
        );
  }

  String _priorityLabel(String? priority) {
    switch (priority) {
      case 'HIGH':
        return 'High';
      case 'MEDIUM':
        return 'Medium';
      case 'LOW':
        return 'Low';
      default:
        return '';
    }
  }

  Color _priorityColor(String? priority) {
    switch (priority) {
      case 'HIGH':
        return Colors.redAccent;
      case 'MEDIUM':
        return Colors.orangeAccent;
      case 'LOW':
        return Colors.lightGreen;
      default:
        return Colors.white54;
    }
  }

  // ─── Top bars ───

  Widget _buildNormalBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'TASKS',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'sf_pro',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white, size: 24),
          onPressed: _showCreateTaskDialog,
        ),
      ],
    );
  }

  Widget _buildSelectionBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _clearSelection,
        ),
        Expanded(
          child: Center(
            child: Text(
              '${_selectedTaskIds.length} selected',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'sf_pro',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _confirmAndDeleteTasks(_selectedTaskIds.toList()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(tasksAutoSyncProvider);
    final wsState = ref.watch(workspaceViewModelProvider);
    final selectedWorkspace = wsState.selected;

    final tasksState = ref.watch(tasksViewModelProvider);

    final isBusy = tasksState.status == TasksStatus.loading ||
        tasksState.status == TasksStatus.creating ||
        tasksState.status == TasksStatus.deleting;

    return GradientScaffold(
      useDashboardGradient: true,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ======= TOP BAR =======
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child:
                  _isSelectionMode ? _buildSelectionBar() : _buildNormalBar(),
            ),

            // ======= SYNC STATUS =======
            if (syncState.isSyncing)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Syncing\u2026",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'sf_pro',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!syncState.isSyncing && _showSynced)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.green.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green, size: 14),
                        SizedBox(width: 8),
                        Text(
                          "Synced",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontFamily: 'sf_pro',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ======= BODY =======
            Expanded(
              child: Builder(
                builder: (_) {
                  if (selectedWorkspace == null) {
                    return const Center(
                      child: Text(
                        "Select a workspace to see tasks",
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  if (isBusy && tasksState.tasks.isEmpty) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFAEFB2A)),
                    );
                  }

                  if (tasksState.status == TasksStatus.error) {
                    return Center(
                      child: Text(
                        tasksState.error ?? "Something went wrong",
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (tasksState.tasks.isEmpty) {
                    return const Center(
                      child: Text(
                        "No tasks yet.\nTap + to create one.",
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      final ws = ref.read(workspaceViewModelProvider).selected;
                      if (ws != null) {
                        await ref
                            .read(tasksViewModelProvider.notifier)
                            .refreshWorkspaceTasks(ws.id);
                      }
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 10, bottom: 120),
                      itemCount: tasksState.tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasksState.tasks[index];
                        final isSelected = _selectedTaskIds.contains(task.id);

                        final date =
                            (task.updatedAt ?? task.createdAt)?.toLocal();
                        final formattedTime = date != null
                            ? DateFormat("dd MMM yyyy • HH:mm").format(date)
                            : "";

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Dismissible(
                            key: ValueKey(task.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              await _confirmAndDeleteTasks([task.id]);
                              return false;
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.white, size: 28),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleSelection(task.id);
                                } else {
                                  _toggleTaskCompletion(task);
                                }
                              },
                              onLongPress: () => _toggleSelection(task.id),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFAEFB2A)
                                          .withOpacity(0.12)
                                      : Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFAEFB2A)
                                            .withOpacity(0.6)
                                        : Colors.white.withOpacity(0.12),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Checkbox / selection indicator
                                    GestureDetector(
                                      onTap: () => _toggleTaskCompletion(task),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        margin: const EdgeInsets.only(top: 2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? const Color(0xFFAEFB2A)
                                              : task.isCompleted
                                                  ? const Color(0xFFAEFB2A)
                                                  : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFFAEFB2A)
                                                : task.isCompleted
                                                    ? const Color(0xFFAEFB2A)
                                                    : Colors.white54,
                                            width: 2,
                                          ),
                                        ),
                                        child: (isSelected || task.isCompleted)
                                            ? const Icon(Icons.check,
                                                color: Colors.black, size: 16)
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Task content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.title,
                                            style: TextStyle(
                                              fontFamily: 'sf_pro',
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              decoration: task.isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              decorationColor: Colors.white54,
                                            ),
                                          ),
                                          if (task.description != null &&
                                              task.description!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              task.description!,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'sf_pro',
                                                color: Colors.white
                                                    .withOpacity(0.6),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              if (task.priority != null) ...[
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: _priorityColor(
                                                            task.priority)
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    _priorityLabel(
                                                        task.priority),
                                                    style: TextStyle(
                                                      fontFamily: 'sf_pro',
                                                      color: _priorityColor(
                                                          task.priority),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Text(
                                                formattedTime,
                                                style: TextStyle(
                                                  fontFamily: 'sf_pro',
                                                  color: Colors.white
                                                      .withOpacity(0.4),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Edit button
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: Colors.white54, size: 20),
                                      onPressed: () =>
                                          _showEditTaskDialog(task),
                                      splashRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

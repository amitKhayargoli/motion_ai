import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:motion_ai/feature/home/presentation/pages/widgets/gradient_scaffold_widget.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/view_model/rag_chatbot_view_model.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/state/rag_chatbot_state.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/pages/thread_chat_page.dart';

class ThreadHistoryPage extends ConsumerStatefulWidget {
  const ThreadHistoryPage({super.key});

  @override
  ConsumerState<ThreadHistoryPage> createState() => _ThreadHistoryPageState();
}

class _ThreadHistoryPageState extends ConsumerState<ThreadHistoryPage> {
  final Set<String> _selectedThreadIds = {};

  bool get _isSelectionMode => _selectedThreadIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ws = ref.read(workspaceViewModelProvider).selected;
      if (ws != null) {
        await ref
            .read(ragChatbotViewModelProvider.notifier)
            .fetchThreads(workspaceId: ws.id);
      }
    });
  }

  void _toggleSelection(String threadId) {
    setState(() {
      if (_selectedThreadIds.contains(threadId)) {
        _selectedThreadIds.remove(threadId);
      } else {
        _selectedThreadIds.add(threadId);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedThreadIds.clear());
  }

  Future<void> _confirmAndDeleteThreads(List<String> threadIds) async {
    final ws = ref.read(workspaceViewModelProvider).selected;
    if (ws == null) return;

    final count = threadIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A0F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete ${count == 1 ? 'Chat' : '$count Chats'}?',
          style: const TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
        ),
        content: Text(
          count == 1
              ? 'This chat will be permanently deleted.'
              : 'These $count chats will be permanently deleted.',
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

    if (confirmed != true) return;

    if (count == 1) {
      await ref.read(ragChatbotViewModelProvider.notifier).deleteThread(
            workspaceId: ws.id,
            threadId: threadIds.first,
          );
    } else {
      await ref.read(ragChatbotViewModelProvider.notifier).deleteThreads(
            workspaceId: ws.id,
            threadIds: threadIds,
          );
    }

    _clearSelection();
  }

  Future<void> _showRenameDialog(String threadId, String currentTitle) async {
    final ws = ref.read(workspaceViewModelProvider).selected;
    if (ws == null) return;

    final controller = TextEditingController(text: currentTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A0F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Rename Chat',
          style: TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          cursorColor: const Color(0xFFAEFB2A),
          style: const TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
          decoration: InputDecoration(
            hintText: 'Chat title',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFAEFB2A)),
            ),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70, fontFamily: 'sf_pro')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save',
                style:
                    TextStyle(color: Color(0xFFAEFB2A), fontFamily: 'sf_pro')),
          ),
        ],
      ),
    );

    if (newTitle == null || newTitle.isEmpty || newTitle == currentTitle)
      return;

    await ref.read(ragChatbotViewModelProvider.notifier).updateThreadTitle(
          workspaceId: ws.id,
          threadId: threadId,
          title: newTitle,
        );
  }

  @override
  Widget build(BuildContext context) {
    final ws = ref.watch(workspaceViewModelProvider).selected;
    final st = ref.watch(ragChatbotViewModelProvider);

    return GradientScaffold(
      useDashboardGradient: true,
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ===== TOP BAR =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child:
                  _isSelectionMode ? _buildSelectionBar() : _buildNormalBar(),
            ),

            const SizedBox(height: 8),

            // ===== THREAD LIST =====
            Expanded(
              child: Builder(
                builder: (_) {
                  if (ws == null) {
                    return const Center(
                      child: Text(
                        "Select a workspace first",
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  if (st.status == RagChatbotStatus.loading) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFAEFB2A)),
                    );
                  }

                  if (st.status == RagChatbotStatus.error &&
                      st.threads.isEmpty) {
                    return Center(
                      child: Text(
                        st.error ?? "Failed to load threads",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  if (st.threads.isEmpty) {
                    return const Center(
                      child: Text(
                        "No chats yet",
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    itemCount: st.threads.length,
                    itemBuilder: (context, i) {
                      final t = st.threads[i];
                      final isSelected = _selectedThreadIds.contains(t.id);
                      final dt = (t.updatedAt ?? t.createdAt)?.toLocal();
                      final time = dt != null
                          ? DateFormat("dd MMM yyyy  HH:mm").format(dt)
                          : "";

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Dismissible(
                          key: ValueKey(t.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            await _confirmAndDeleteThreads([t.id]);
                            return false;
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.white, size: 28),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleSelection(t.id);
                              } else if (ws != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ThreadChatPage(
                                      workspaceId: ws.id,
                                      threadId: t.id,
                                    ),
                                  ),
                                );
                              }
                            },
                            onLongPress: () => _toggleSelection(t.id),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFAEFB2A).withOpacity(0.12)
                                    : Colors.black.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFAEFB2A).withOpacity(0.6)
                                      : Colors.white.withOpacity(0.10),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFAEFB2A),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isSelected
                                          ? Icons.check
                                          : Icons.chat_bubble_outline,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'sf_pro',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          time,
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontFamily: 'sf_pro',
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: Colors.white54, size: 20),
                                    onPressed: () =>
                                        _showRenameDialog(t.id, t.title),
                                    splashRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              'CHAT HISTORY',
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
        const SizedBox(width: 48),
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
              '${_selectedThreadIds.length} selected',
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
          onPressed: () =>
              _confirmAndDeleteThreads(_selectedThreadIds.toList()),
        ),
      ],
    );
  }
}

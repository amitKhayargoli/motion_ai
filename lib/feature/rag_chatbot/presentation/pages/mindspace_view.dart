import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:motion_ai/feature/home/presentation/pages/widgets/gradient_scaffold_widget.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/presentation/pages/note_editor.dart';
import 'package:motion_ai/feature/notes/presentation/view_model/notes_view_model.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/entities/chat_message_entity.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

import 'package:motion_ai/feature/rag_chatbot/presentation/view_model/rag_chatbot_view_model.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/state/rag_chatbot_state.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/pages/thread_history_page.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/widgets/chat_bubble.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/widgets/chat_typing_bubble.dart';

class MindspaceView extends ConsumerStatefulWidget {
  const MindspaceView({super.key});

  @override
  ConsumerState<MindspaceView> createState() => _MindspaceViewState();
}

class _MindspaceViewState extends ConsumerState<MindspaceView> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  NoteEntity? _contextNote;

  late final ProviderSubscription<RagChatbotState> _ragSub;

  @override
  void initState() {
    super.initState();

    _ragSub = ref.listenManual<RagChatbotState>(
      ragChatbotViewModelProvider,
      (prev, next) {
        final prevLen = prev?.messages.length ?? 0;
        final nextLen = next.messages.length;

        if (prevLen != nextLen ||
            (prev?.assistantTyping != next.assistantTyping)) {
          _scrollToBottom();
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncPendingForActiveThread();
    });
  }

  @override
  void dispose() {
    _ragSub.close();
    _chatController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _htmlToPlainText(String html) {
    if (html.trim().isEmpty) return '';

    final document = html_parser.parse(html);
    final text = document.body?.text ?? '';

    return text
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
        .trim();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 160,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _syncPendingForActiveThread() async {
    final ws = ref.read(workspaceViewModelProvider).selected;
    final threadId = ref.read(ragChatbotViewModelProvider).activeThreadId;

    if (ws == null) return;
    if (threadId == null || threadId.isEmpty) return;

    await ref.read(ragChatbotViewModelProvider.notifier).syncPendingMessages(
          workspaceId: ws.id,
          threadId: threadId,
        );
  }

  Future<void> _createNewThread() async {
    // Already on a fresh empty chat — don't create a duplicate.
    final currentMessages = ref.read(ragChatbotViewModelProvider).messages;
    if (currentMessages.isEmpty) return;

    final ws = ref.read(workspaceViewModelProvider).selected;
    if (ws == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a workspace first")),
      );
      return;
    }

    await ref.read(ragChatbotViewModelProvider.notifier).startNewThread(
          workspaceId: ws.id,
        );

    if (!mounted) return;
    _chatController.clear();
    _scrollToBottom();
  }

  Future<void> _handleSendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final ws = ref.read(workspaceViewModelProvider).selected;
    if (ws == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a workspace first")),
      );
      return;
    }

    final ctx = _contextNote;
    final cleanContextContent =
        ctx != null ? _htmlToPlainText(ctx.content).trim() : '';

    final message = ctx != null
        ? 'Note: "${ctx.title}"\n\n$cleanContextContent\n\n$text'
        : text;

    _chatController.clear();
    setState(() => _contextNote = null);

    await ref
        .read(ragChatbotViewModelProvider.notifier)
        .sendMessageEnsureThread(
          workspaceId: ws.id,
          message: message,
        );

    _scrollToBottom();
  }

  void _showNotePicker() {
    final notes = ref.read(notesViewModelProvider).notes;
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No notes in this workspace yet')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add note as context',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'sf_pro',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: notes.length,
                itemBuilder: (ctx, i) {
                  final note = notes[i];
                  return ListTile(
                    leading: const Icon(
                      Icons.description_outlined,
                      color: Color(0xFFAEFB2A),
                      size: 20,
                    ),
                    title: Text(
                      note.title.isEmpty ? 'Untitled' : note.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'sf_pro',
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _contextNote = note);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _openNote(ChatNoteRef noteRef) {
    final notes = ref.read(notesViewModelProvider).notes;
    final matches = notes.where((n) => n.id == noteRef.id);
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note not found')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorPage(note: matches.first)),
    );
  }

  Future<void> _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ThreadHistoryPage()),
    );
    if (!mounted) return;
    ref.read(ragChatbotViewModelProvider.notifier).clearChat();
  }

  @override
  Widget build(BuildContext context) {
    final ragState = ref.watch(ragChatbotViewModelProvider);
    final ws = ref.watch(workspaceViewModelProvider).selected;

    final isSending = ragState.chatStatus == RagChatStatus.syncing;

    return GradientScaffold(
      useDashboardGradient: true,
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'MINDSPACE',
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
                    icon: Icon(
                      Icons.add,
                      color: (isSending || ragState.messages.isEmpty)
                          ? Colors.white24
                          : Colors.white,
                    ),
                    onPressed: (isSending || ragState.messages.isEmpty)
                        ? null
                        : _createNewThread,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ragState.messages.isEmpty
                  ? _EmptyMindspace(wsSelected: ws != null)
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      itemCount: ragState.messages.length +
                          (ragState.assistantTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (ragState.assistantTyping &&
                            index == ragState.messages.length) {
                          return const ChatTypingBubble();
                        }

                        final m = ragState.messages[index];
                        final isUser = m.role == "user";

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () async {
                                if (!isUser) return;
                                if (!m.failed) return;
                                if (ws == null) return;

                                await ref
                                    .read(ragChatbotViewModelProvider.notifier)
                                    .resendMessage(
                                      workspaceId: ws.id,
                                      threadId: m.threadId,
                                      messageId: m.id,
                                    );
                              },
                              child: ChatBubble(
                                text: m.content,
                                isUser: isUser,
                                pending: m.pending,
                                failed: m.failed,
                                notes: m.notes,
                                onNoteTap: _openNote,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFAEFB2A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _showNotePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '@',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Add Context',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'sf_pro',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_contextNote != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  size: 13,
                                  color: Colors.black87,
                                ),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 110),
                                  child: Text(
                                    _contextNote!.title.isEmpty
                                        ? 'Untitled'
                                        : _contextNote!.title,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontFamily: 'sf_pro',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _contextNote = null),
                                  child: const Icon(
                                    Icons.close,
                                    size: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            cursorColor: Colors.black,
                            style: const TextStyle(
                              color: Colors.black,
                              fontFamily: 'sf_pro',
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Ask MindSpace anything...',
                              hintStyle: TextStyle(color: Colors.black54),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (_) => _handleSendMessage(),
                          ),
                        ),
                        GestureDetector(
                          onTap: isSending ? null : _handleSendMessage,
                          child: Opacity(
                            opacity: isSending ? 0.6 : 1,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF4DE1C9),
                              ),
                              child: isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : Image.asset(
                                      "assets/images/send.png",
                                      width: 18,
                                      height: 18,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (ws != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.apps_rounded,
                            size: 13,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Source: ',
                            style: TextStyle(
                              color: Colors.black54,
                              fontFamily: 'sf_pro',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              ws.name,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontFamily: 'sf_pro',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: GestureDetector(
                onTap: _openHistory,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 20, color: Color(0xFFAEFB2A)),
                    SizedBox(width: 8),
                    Text(
                      'MindSpace Chat History',
                      style: TextStyle(
                        color: Color(0xFFAEFB2A),
                        fontFamily: 'sf_pro',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMindspace extends StatelessWidget {
  const _EmptyMindspace({required this.wsSelected});
  final bool wsSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 18),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Image.asset("assets/images/logo.png"),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Chat with your notes',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'sf_pro',
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          wsSelected
              ? 'What can I help you discover?'
              : 'Select a workspace first',
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'sf_pro',
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

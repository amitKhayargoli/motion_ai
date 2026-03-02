import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/gradient_scaffold_widget.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/view_model/rag_chatbot_view_model.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/state/rag_chatbot_state.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/widgets/chat_bubble.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/widgets/chat_typing_bubble.dart';

class ThreadChatPage extends ConsumerStatefulWidget {
  const ThreadChatPage({
    super.key,
    required this.workspaceId,
    required this.threadId,
  });

  final String workspaceId;
  final String threadId;

  @override
  ConsumerState<ThreadChatPage> createState() => _ThreadChatPageState();
}

class _ThreadChatPageState extends ConsumerState<ThreadChatPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

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
      await ref.read(ragChatbotViewModelProvider.notifier).openThread(
            workspaceId: widget.workspaceId,
            threadId: widget.threadId,
          );
    });
  }

  @override
  void dispose() {
    _ragSub.close();
    _chatController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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

  Future<void> _handleSendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    _chatController.clear();

    await ref
        .read(ragChatbotViewModelProvider.notifier)
        .sendMessageEnsureThread(
          workspaceId: widget.workspaceId,
          message: text,
          threadId: widget.threadId,
        );

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final ragState = ref.watch(ragChatbotViewModelProvider);
    final isSending = ragState.chatStatus == RagChatStatus.syncing;

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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
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
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ===== CHAT LIST =====
            Expanded(
              child: ragState.status == RagChatbotStatus.loading &&
                      ragState.messages.isEmpty
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFAEFB2A)),
                    )
                  : ragState.messages.isEmpty
                      ? const Center(
                          child: Text(
                            'No messages yet',
                            style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'sf_pro',
                              fontSize: 16,
                            ),
                          ),
                        )
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

                                    await ref
                                        .read(ragChatbotViewModelProvider
                                            .notifier)
                                        .resendMessage(
                                          workspaceId: widget.workspaceId,
                                          threadId: m.threadId,
                                          messageId: m.id,
                                        );
                                  },
                                  child: ChatBubble(
                                    text: m.content,
                                    isUser: isUser,
                                    pending: m.pending,
                                    failed: m.failed,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // ===== INPUT BOX =====
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
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('@',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
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
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 18),
                        SizedBox(width: 4),
                        Text('Auto', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 16),
                        Icon(Icons.source, size: 18),
                        SizedBox(width: 4),
                        Text('All sources', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 16),
                        Icon(Icons.calendar_month_rounded, size: 18),
                        SizedBox(width: 4),
                        Text('AnyTime', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../state/rag_chatbot_state.dart';
import '../../domain/repositories/rag_chatbot_repository.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../providers/rag_chatbot_providers.dart';

final ragChatbotViewModelProvider =
    NotifierProvider<RagChatbotViewModel, RagChatbotState>(
  RagChatbotViewModel.new,
);

class RagChatbotViewModel extends Notifier<RagChatbotState> {
  Timer? _revealTimer;

  IRagChatbotRepository get _repo => ref.read(ragChatbotRepositoryProvider);

  @override
  RagChatbotState build() => RagChatbotState.initial();

  void clearError() => state = state.copyWith(clearError: true);

  void clearChat() {
    state = state.copyWith(
      clearActiveThreadId: true,
      messages: const [],
      assistantTyping: false,
      chatStatus: RagChatStatus.idle,
    );
  }

  // =========================================================
  // THREADS
  // =========================================================

  Future<void> startNewThread({required String workspaceId}) async {
    clearError();

    state = state.copyWith(
      status: RagChatbotStatus.loading,
      activeWorkspaceId: workspaceId,
      clearActiveThreadId: true,
      messages: const [],
      assistantTyping: false,
      chatStatus: RagChatStatus.idle,
    );

    final res =
        await _repo.createThread(workspaceId: workspaceId, title: "New chat");

    res.fold(
      (f) => state =
          state.copyWith(status: RagChatbotStatus.error, error: f.message),
      (thread) {
        state = state.copyWith(
          status: RagChatbotStatus.ready,
          activeWorkspaceId: workspaceId,
          activeThreadId: thread.id,
          messages: thread.messages,
        );
      },
    );
  }

  Future<String?> createThreadIfNeeded({
    required String workspaceId,
    String? title,
  }) async {
    final active = state.activeThreadId;
    print("createThreadIfNeeded() activeThreadId=$active");

    if (active != null && active.isNotEmpty) return active;

    print("No active thread -> creating NEW thread now");

    state = state.copyWith(status: RagChatbotStatus.loading);

    final res =
        await _repo.createThread(workspaceId: workspaceId, title: title);

    return res.fold(
      (f) {
        state =
            state.copyWith(status: RagChatbotStatus.error, error: f.message);
        return null;
      },
      (thread) {
        print("created threadId=${thread.id}");
        state = state.copyWith(
          status: RagChatbotStatus.ready,
          activeThreadId: thread.id,
          messages: thread.messages,
        );
        return thread.id;
      },
    );
  }

  Future<void> openThread({
    required String workspaceId,
    required String threadId,
    bool syncPendingAfterOpen = true,
  }) async {
    // Skip if this thread is already active and loaded
    if (state.activeThreadId == threadId &&
        state.messages.isNotEmpty &&
        state.status == RagChatbotStatus.ready) {
      return;
    }

    clearError();

    state = state.copyWith(
      status: RagChatbotStatus.loading,
      activeThreadId: threadId,
      messages: const [],
      assistantTyping: false,
      chatStatus: RagChatStatus.idle,
    );

    final res = await _repo.getThread(threadId: threadId);

    await res.fold(
      (f) async {
        state =
            state.copyWith(status: RagChatbotStatus.error, error: f.message);
      },
      (thread) async {
        state = state.copyWith(
          status: RagChatbotStatus.ready,
          activeWorkspaceId: workspaceId,
          activeThreadId: thread.id,
          messages: thread.messages,
        );

        if (syncPendingAfterOpen) {
          await syncPendingMessages(
              workspaceId: workspaceId, threadId: threadId);
        }
      },
    );
  }

  Future<void> fetchThreads({required String workspaceId}) async {
    // Only show the loading spinner when there are no threads yet;
    // otherwise silently refresh in the background so stale data is not shown.
    if (state.threads.isEmpty) {
      state = state.copyWith(status: RagChatbotStatus.loading);
    }

    final res = await _repo.listThreads(workspaceId: workspaceId);

    res.fold(
      (f) => state =
          state.copyWith(status: RagChatbotStatus.error, error: f.message),
      (threads) => state = state.copyWith(
          status: RagChatbotStatus.ready,
          threads: threads,
          activeWorkspaceId: workspaceId),
    );
  }

  // =========================================================
  // DELETE THREADS
  // =========================================================

  Future<void> deleteThread({
    required String workspaceId,
    required String threadId,
  }) async {
    final res = await _repo.deleteThread(threadId: threadId);

    res.fold(
      (f) => state =
          state.copyWith(status: RagChatbotStatus.error, error: f.message),
      (_) {
        // If the deleted thread was active, clear it
        if (state.activeThreadId == threadId) {
          state = state.copyWith(
            clearActiveThreadId: true,
            messages: const [],
          );
        }
      },
    );

    await fetchThreads(workspaceId: workspaceId);
  }

  Future<void> deleteThreads({
    required String workspaceId,
    required List<String> threadIds,
  }) async {
    for (final id in threadIds) {
      await _repo.deleteThread(threadId: id);
    }

    // If the active thread was among the deleted ones, clear it
    if (threadIds.contains(state.activeThreadId)) {
      state = state.copyWith(
        clearActiveThreadId: true,
        messages: const [],
      );
    }

    await fetchThreads(workspaceId: workspaceId);
  }

  // =========================================================
  // UPDATE THREAD TITLE
  // =========================================================

  Future<void> updateThreadTitle({
    required String workspaceId,
    required String threadId,
    required String title,
  }) async {
    final res = await _repo.updateThreadTitle(threadId: threadId, title: title);

    res.fold(
      (f) => state =
          state.copyWith(status: RagChatbotStatus.error, error: f.message),
      (_) {},
    );

    await fetchThreads(workspaceId: workspaceId);
  }

  // =========================================================
  // PENDING SYNC (important for offline queue)
  // =========================================================

  Future<void> syncPendingMessages({
    required String workspaceId,
    required String threadId,
  }) async {
    state = state.copyWith(chatStatus: RagChatStatus.syncing);

    final res = await _repo.syncPendingMessages(
      workspaceId: workspaceId,
      threadId: threadId,
    );

    await res.fold(
      (f) async {
        state = state.copyWith(
          status: RagChatbotStatus.error,
          error: f.message,
          chatStatus: RagChatStatus.idle,
          assistantTyping: false,
        );
      },
      (_) async {
        final t = await _repo.getThread(threadId: threadId);

        t.fold(
          (f) => state = state.copyWith(
            status: RagChatbotStatus.error,
            error: f.message,
            chatStatus: RagChatStatus.idle,
          ),
          (thread) {
            state = state.copyWith(
              status: RagChatbotStatus.ready,
              activeThreadId: thread.id,
              messages: thread.messages,
              chatStatus: RagChatStatus.idle,
              assistantTyping: false,
            );
          },
        );
      },
    );
  }

  // =========================================================
  // CHAT (send + retry)
  // =========================================================

  Future<void> sendMessageEnsureThread({
    required String workspaceId,
    required String message,
    String? threadId,
  }) async {
    clearError();

    final text = message.trim();
    if (text.isEmpty) return;

    print(
        "sendMessageEnsureThread BEFORE activeThreadId=${state.activeThreadId}");

    final resolvedThreadId = threadId ??
        await createThreadIfNeeded(
          workspaceId: workspaceId,
          title: "New chat",
        );
    print("sendMessageEnsureThread USING threadId=$resolvedThreadId");
    if (resolvedThreadId == null) return;

    // 1) Add pending user bubble locally (UX)
    final localUser = ChatMessageEntity(
      id: "local_${const Uuid().v4()}",
      threadId: resolvedThreadId,
      role: "user",
      content: text,
      createdAt: DateTime.now(),
      pending: true,
      failed: false,
    );

    state = state.copyWith(
      status: RagChatbotStatus.ready,
      chatStatus: RagChatStatus.syncing,
      assistantTyping: true,
      activeThreadId: resolvedThreadId,
      messages: [...state.messages, localUser],
    );

    // 2) Repository handles: save local, enqueue, sync if online, refresh server truth
    final res = await _repo.chat(
      workspaceId: workspaceId,
      threadId: resolvedThreadId,
      message: text,
    );

    res.fold(
      (f) {
        final updated = state.messages.map((m) {
          if (m.id == localUser.id) {
            return m.copyWith(pending: false, failed: true);
          }
          return m;
        }).toList();

        state = state.copyWith(
          status: RagChatbotStatus.error,
          error: f.message,
          chatStatus: RagChatStatus.idle,
          assistantTyping: false,
          messages: updated,
        );
      },
      (msgs) {
        // Always keep the known threadId.
        // Never re-derive from message fields — API may omit threadId.
        state = state.copyWith(
          status: RagChatbotStatus.ready,
          chatStatus: RagChatStatus.idle,
          assistantTyping: false,
          activeThreadId: resolvedThreadId,
          messages: msgs,
        );

        _animateLastAssistantReveal();
      },
    );
  }

  Future<void> resendMessage({
    required String workspaceId,
    required String threadId,
    required String messageId,
  }) async {
    clearError();

    final idx = state.messages.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;

    final msg = state.messages[idx];
    if (msg.role != "user") return;

    // 1) mark it pending again in UI
    final updated = [...state.messages];
    updated[idx] = updated[idx].copyWith(pending: true, failed: false);

    state = state.copyWith(
      chatStatus: RagChatStatus.syncing,
      assistantTyping: true,
      messages: updated,
    );

    // 2) Call repo.chat again; repo will enqueue + sync if online
    final res = await _repo.chat(
      workspaceId: workspaceId,
      threadId: threadId,
      message: msg.content,
    );

    res.fold(
      (f) {
        final failed = [...state.messages];
        final i = failed.indexWhere((m) => m.id == messageId);
        if (i >= 0) {
          failed[i] = failed[i].copyWith(pending: false, failed: true);
        }

        state = state.copyWith(
          status: RagChatbotStatus.error,
          error: f.message,
          assistantTyping: false,
          chatStatus: RagChatStatus.idle,
          messages: failed,
        );
      },
      (msgs) {
        // Always keep the known threadId parameter.
        // Never re-derive from message fields — API may omit threadId.
        state = state.copyWith(
          status: RagChatbotStatus.ready,
          assistantTyping: false,
          chatStatus: RagChatStatus.idle,
          activeThreadId: threadId,
          messages: msgs,
        );

        _animateLastAssistantReveal();
      },
    );
  }

  // =========================================================
  // STREAMING REVEAL
  // =========================================================

  void _animateLastAssistantReveal() {
    _revealTimer?.cancel();

    final msgs = state.messages;
    if (msgs.isEmpty) return;

    final idx = msgs.lastIndexWhere(
      (m) => m.role == "assistant" && m.content.isNotEmpty,
    );
    if (idx < 0) return;

    final full = msgs[idx].content;
    if (full.length < 10) return;

    var t = 0;
    final step = (full.length / 40).ceil().clamp(1, 10);

    final blanked = [...msgs];
    blanked[idx] = blanked[idx].copyWith(content: "");
    state = state.copyWith(messages: blanked);

    _revealTimer = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      t += step;

      if (t >= full.length) {
        final done = [...state.messages];
        done[idx] = done[idx].copyWith(content: full);
        state = state.copyWith(messages: done);
        timer.cancel();
        return;
      }

      final partial = full.substring(0, t);
      final mid = [...state.messages];
      mid[idx] = mid[idx].copyWith(content: partial);
      state = state.copyWith(messages: mid);
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    // super.dispose(); // Riverpod Notifier dispose handled by framework
  }
}

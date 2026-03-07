import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/services/connectivity/network_info.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/view_model/rag_chatbot_view_model.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

class RagChatSyncState {
  final bool isSyncing;
  final DateTime? lastSuccessAt;
  final String? lastError;

  const RagChatSyncState({
    required this.isSyncing,
    this.lastSuccessAt,
    this.lastError,
  });

  RagChatSyncState copyWith({
    bool? isSyncing,
    DateTime? lastSuccessAt,
    String? lastError,
  }) {
    return RagChatSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastError: lastError,
    );
  }

  static const idle = RagChatSyncState(isSyncing: false);
}

final ragChatAutoSyncProvider =
    NotifierProvider<RagChatAutoSyncNotifier, RagChatSyncState>(
  RagChatAutoSyncNotifier.new,
);

class RagChatAutoSyncNotifier extends Notifier<RagChatSyncState> {
  bool _running = false;

  @override
  RagChatSyncState build() => RagChatSyncState.idle;

  Future<void> trySync() async {
    if (_running) return;
    _running = true;
    state = state.copyWith(isSyncing: true, lastError: null);

    try {
      final ok = await ref.read(networkInfoProvider).isConnected;
      if (!ok) return;

      final ws = ref.read(workspaceViewModelProvider).selected;
      if (ws == null) return;

      // Sync thread list — upserts new/updated threads and prunes deleted ones
      await ref.read(ragChatbotViewModelProvider.notifier).fetchThreads(
            workspaceId: ws.id,
          );

      final threadId = ref.read(ragChatbotViewModelProvider).activeThreadId;
      if (threadId != null && threadId.isNotEmpty) {
        await ref
            .read(ragChatbotViewModelProvider.notifier)
            .syncPendingMessages(
              workspaceId: ws.id,
              threadId: threadId,
            );
      }

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
      if (state.isSyncing) {
        state = state.copyWith(isSyncing: false);
      }
    }
  }
}

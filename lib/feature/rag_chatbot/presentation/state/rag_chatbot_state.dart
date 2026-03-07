import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_thread_entity.dart';

enum RagChatbotStatus { idle, loading, ready, error }

enum RagChatStatus { idle, syncing }

class RagChatbotState {
  final RagChatbotStatus status;
  final RagChatStatus chatStatus;
  final String? error;
  final String? activeWorkspaceId;
  final String? activeThreadId;
  final List<ChatMessageEntity> messages;
  final List<ChatThreadEntity> threads;

  /// typing indicator
  final bool assistantTyping;

  const RagChatbotState({
    required this.status,
    required this.chatStatus,
    required this.error,
    required this.activeWorkspaceId,
    required this.activeThreadId,
    required this.messages,
    required this.threads,
    required this.assistantTyping,
  });

  factory RagChatbotState.initial() => const RagChatbotState(
        status: RagChatbotStatus.idle,
        chatStatus: RagChatStatus.idle,
        error: null,
        activeWorkspaceId: null,
        activeThreadId: null,
        messages: [],
        threads: [],
        assistantTyping: false,
      );

  RagChatbotState copyWith({
    RagChatbotStatus? status,
    RagChatStatus? chatStatus,
    String? error,
    bool clearError = false,
    String? activeThreadId,
    bool clearActiveThreadId = false,
    List<ChatMessageEntity>? messages,
    List<ChatThreadEntity>? threads,
    bool? assistantTyping,
    String? activeWorkspaceId,
  }) {
    return RagChatbotState(
      status: status ?? this.status,
      chatStatus: chatStatus ?? this.chatStatus,
      error: clearError ? null : (error ?? this.error),
      activeWorkspaceId: activeWorkspaceId ?? this.activeWorkspaceId,
      activeThreadId:
          clearActiveThreadId ? null : (activeThreadId ?? this.activeThreadId),
      messages: messages ?? this.messages,
      threads: threads ?? this.threads,
      assistantTyping: assistantTyping ?? this.assistantTyping,
    );
  }
}

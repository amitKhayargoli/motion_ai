class ChatNoteRef {
  final String id;
  final String title;
  const ChatNoteRef({required this.id, required this.title});
}

class ChatMessageEntity {
  final String id;
  final String threadId;
  final String role; // "user" | "assistant"
  final String content;
  final DateTime? createdAt;

  final bool pending; // true if not synced yet
  final bool failed; // true if send failed (tap to retry)

  /// Set for assistant messages with kind "note_list" or "latest_notes"
  final String? kind;
  final List<ChatNoteRef>? notes;

  const ChatMessageEntity({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    this.createdAt,
    this.pending = false,
    this.failed = false,
    this.kind,
    this.notes,
  });

  ChatMessageEntity copyWith({
    String? content,
    DateTime? createdAt,
    bool? pending,
    bool? failed,
    String? kind,
    List<ChatNoteRef>? notes,
  }) {
    return ChatMessageEntity(
      id: id,
      threadId: threadId,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      pending: pending ?? this.pending,
      failed: failed ?? this.failed,
      kind: kind ?? this.kind,
      notes: notes ?? this.notes,
    );
  }
}

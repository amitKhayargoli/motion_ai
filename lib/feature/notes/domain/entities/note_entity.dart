enum NoteSyncStatus {
  synced,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
}

class NoteEntity {
  final String id;
  final String workspaceId;
  final String title;
  final String content;
  final String? summary;

  final String? audioFileId;
  final String? type; // MANUAL | VOICE_TRANSCRIPT | MEETING_SUMMARY
  final String? status; // DRAFT | PROCESSING | PUBLISHED

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final NoteSyncStatus syncStatus;

  const NoteEntity({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.content,
    this.summary,
    this.audioFileId,
    this.type,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = NoteSyncStatus.synced,
  });

  NoteEntity copyWith({
    String? title,
    String? content,
    String? summary,
    String? audioFileId,
    String? type,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    NoteSyncStatus? syncStatus,
  }) {
    return NoteEntity(
      id: id,
      workspaceId: workspaceId,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      audioFileId: audioFileId ?? this.audioFileId,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

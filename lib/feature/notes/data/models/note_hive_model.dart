import 'package:hive/hive.dart';
import 'package:motion_ai/core/constants/hive_table_constant.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';

part 'note_hive_model.g.dart';

/// 0 = synced
/// 1 = pendingCreate
/// 2 = pendingUpdate
/// 3 = pendingDelete (optional if you want soft-delete; we hard-delete locally)
@HiveType(typeId: HiveTableConstant.notesTypeId)
class NoteHiveModel extends HiveObject {
  @HiveField(0)
  final String id; // local id (can be temp local_xxx OR real server id)

  @HiveField(1)
  final String workspaceId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final String? summary;

  @HiveField(5)
  final DateTime? createdAt;

  @HiveField(6)
  final DateTime? updatedAt;

  // ✅ NEW: sync helpers
  @HiveField(7)
  final int syncStatus; // 0/1/2

  /// ✅ NEW: if this is a temp local note, serverId is null until synced.
  /// If synced, serverId == real server note id.
  @HiveField(8)
  final String? serverId;

  NoteHiveModel({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.content,
    this.summary,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
    this.serverId,
  });

  NoteEntity toEntity() => NoteEntity(
        id: serverId ?? id, // use serverId if exists
        workspaceId: workspaceId,
        title: title,
        content: content,
        summary: summary,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory NoteHiveModel.fromEntity(
    NoteEntity e, {
    int syncStatus = 0,
    String? serverId,
    String? localId,
  }) {
    return NoteHiveModel(
      id: localId ?? e.id,
      workspaceId: e.workspaceId,
      title: e.title,
      content: e.content,
      summary: e.summary,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      syncStatus: syncStatus,
      serverId: serverId,
    );
  }

  NoteHiveModel copyWith({
    String? id,
    String? workspaceId,
    String? title,
    String? content,
    String? summary,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
    String? serverId,
  }) {
    return NoteHiveModel(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      serverId: serverId ?? this.serverId,
    );
  }
}

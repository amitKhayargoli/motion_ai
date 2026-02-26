import 'package:motion_ai/feature/audio_file/data/models/audio_file_api_model.dart';

import '../../data/models/audio_file_hive_model.dart';

class AudioFileEntity {
  final String id;
  final String? title;
  final String? fileName;
  final String localPath;
  final String? cloudUrl;
  final int? durationSeconds;
  final String? mimeType;
  final DateTime? uploadedAt;
  final String uploaderId;
  final String? noteId;
  final String? meetingLinkId;
  final String username;
  final int syncStatus; // 0=synced, 1=pendingUpload, 2=pendingUpdate

  const AudioFileEntity({
    this.id = '',
    this.title,
    this.fileName,
    required this.localPath,
    this.cloudUrl,
    this.durationSeconds,
    this.mimeType,
    this.uploadedAt,
    required this.uploaderId,
    this.noteId,
    this.meetingLinkId,
    required this.username,
    this.syncStatus = 0,
  });

  /// User-set title takes priority; fall back to the storage filename
  String get displayName => title ?? fileName ?? 'Untitled Recording';

  AudioFileEntity copyWith({
    String? id,
    String? title,
    String? fileName,
    String? localPath,
    String? cloudUrl,
    int? durationSeconds,
    String? mimeType,
    DateTime? uploadedAt,
    String? uploaderId,
    String? noteId,
    String? meetingLinkId,
    String? username,
    int? syncStatus,
  }) {
    return AudioFileEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      cloudUrl: cloudUrl ?? this.cloudUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      mimeType: mimeType ?? this.mimeType,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploaderId: uploaderId ?? this.uploaderId,
      noteId: noteId ?? this.noteId,
      meetingLinkId: meetingLinkId ?? this.meetingLinkId,
      username: username ?? this.username,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  factory AudioFileEntity.fromHiveModel(AudioFileHiveModel model) {
    return AudioFileEntity(
      id: model.id,
      title: model.title,
      fileName: model.fileName,
      localPath: model.localPath,
      cloudUrl: model.cloudUrl,
      durationSeconds: model.durationSeconds,
      mimeType: model.mimeType,
      uploadedAt: model.uploadedAt,
      uploaderId: model.uploaderId,
      username: '',
      syncStatus: model.syncStatus,
    );
  }

  AudioFileHiveModel toHiveModel() {
    return AudioFileHiveModel(
      id: id,
      title: title,
      fileName: fileName ?? '',
      localPath: localPath,
      cloudUrl: cloudUrl ?? '',
      durationSeconds: durationSeconds ?? 0,
      mimeType: mimeType ?? '',
      uploadedAt: uploadedAt ?? DateTime.now(),
      uploaderId: uploaderId,
      syncStatus: syncStatus,
    );
  }

  factory AudioFileEntity.fromApiModel(AudioFileApiModel model) {
    return AudioFileEntity(
      id: model.id!,
      title: model.title,
      fileName: model.fileName,
      localPath: '',
      cloudUrl: model.cloudUrl,
      durationSeconds: model.durationSeconds,
      mimeType: model.mimeType,
      uploadedAt: model.uploadedAt,
      uploaderId: model.uploaderId,
      username: model.uploader?.username ?? '',
      syncStatus: 0, // data from API is always synced
    );
  }
}

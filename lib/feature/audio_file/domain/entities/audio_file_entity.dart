import 'package:motion_ai/feature/audio_file/data/models/audio_file_api_model.dart';

import '../../data/models/audio_file_hive_model.dart';

class AudioFileEntity {
  final String id;
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

  const AudioFileEntity({
    this.id = '',
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
  });

  AudioFileEntity copyWith({
    String? id,
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
  }) {
    return AudioFileEntity(
      id: id ?? this.id,
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
    );
  }

  factory AudioFileEntity.fromHiveModel(AudioFileHiveModel model) {
    return AudioFileEntity(
      id: model.id,
      fileName: model.fileName,
      localPath: model.localPath,
      cloudUrl: model.cloudUrl,
      durationSeconds: model.durationSeconds,
      mimeType: model.mimeType,
      uploadedAt: model.uploadedAt,
      uploaderId: model.uploaderId,
      username: '', // Provide a default value or modify as needed
    );
  }

  AudioFileHiveModel toHiveModel() {
    return AudioFileHiveModel(
      id: id,
      fileName: fileName ?? '',
      localPath: localPath,
      cloudUrl: cloudUrl ?? '',
      durationSeconds: durationSeconds ?? 0,
      mimeType: mimeType ?? '',
      uploadedAt: uploadedAt ?? DateTime.now(),
      uploaderId: uploaderId,
    );
  }

  factory AudioFileEntity.fromApiModel(AudioFileApiModel model) {
    return AudioFileEntity(
      id: model.id!,
      fileName: model.fileName,
      localPath: '', // Local path won't be available from API
      cloudUrl: model.cloudUrl,
      durationSeconds: model.durationSeconds,
      mimeType: model.mimeType,
      uploadedAt: model.uploadedAt,
      uploaderId: model.uploaderId,
      username: model.uploader?.username ?? '', // Fixed: Use null-aware access
    );
  }
}

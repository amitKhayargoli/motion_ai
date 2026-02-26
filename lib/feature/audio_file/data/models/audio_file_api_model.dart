import 'package:motion_ai/feature/audio_file/data/models/audio_file_hive_model.dart';
import 'package:motion_ai/feature/audio_file/domain/entities/audio_file_entity.dart';

class UserModel {
  final String id;
  final String username;

  UserModel({required this.id, required this.username});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(id: json['id'], username: json['username']);
  }
}

class AudioFileApiModel {
  final String? id;
  final String? title;
  final String fileName;
  final String cloudUrl;
  final int durationSeconds;
  final String mimeType;
  final String uploaderId;
  final DateTime uploadedAt;
  final UserModel? uploader;

  AudioFileApiModel({
    this.id,
    this.title,
    required this.fileName,
    required this.cloudUrl,
    required this.durationSeconds,
    required this.mimeType,
    required this.uploaderId,
    required this.uploadedAt,
    this.uploader,
  });

  factory AudioFileApiModel.fromJson(Map<String, dynamic> json) {
    return AudioFileApiModel(
      id: json['id'] ?? json['_id'],
      title: json['title'],
      fileName: json['fileName'],
      cloudUrl: json['cloudUrl'],
      durationSeconds: json['durationSeconds'],
      mimeType: json['mimeType'],
      uploaderId: json['uploaderId'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
      uploader: json['uploader'] != null
          ? UserModel.fromJson(json['uploader'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'fileName': fileName,
      'cloudUrl': cloudUrl,
      'durationSeconds': durationSeconds,
      'mimeType': mimeType,
    };
  }

  AudioFileEntity toEntity() {
    return AudioFileEntity(
      id: id!,
      title: title,
      fileName: fileName,
      localPath: '',
      cloudUrl: cloudUrl,
      durationSeconds: durationSeconds,
      mimeType: mimeType,
      uploaderId: uploaderId,
      uploadedAt: uploadedAt,
      username: uploader?.username ?? '',
    );
  }

  AudioFileHiveModel toHiveModel() {
    return AudioFileHiveModel(
      id: id!,
      title: title,
      fileName: fileName,
      localPath: '',
      cloudUrl: cloudUrl,
      durationSeconds: durationSeconds,
      mimeType: mimeType,
      uploaderId: uploaderId,
      uploadedAt: uploadedAt,
      syncStatus: 0, // data from API is always synced
    );
  }
}

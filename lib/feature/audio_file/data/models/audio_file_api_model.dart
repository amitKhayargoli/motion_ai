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
  final String fileName;
  final String cloudUrl;
  final int durationSeconds;
  final String mimeType;
  final String uploaderId;
  final DateTime uploadedAt;
  final UserModel? uploader;

  AudioFileApiModel({
    this.id,
    required this.fileName,
    required this.cloudUrl,
    required this.durationSeconds,
    required this.mimeType,
    required this.uploaderId,
    required this.uploadedAt,
    this.uploader, // Make optional
  });

  factory AudioFileApiModel.fromJson(Map<String, dynamic> json) {
    return AudioFileApiModel(
      id: json['id'],
      fileName: json['fileName'],
      cloudUrl: json['cloudUrl'],
      durationSeconds: json['durationSeconds'],
      mimeType: json['mimeType'],
      uploaderId: json['uploaderId'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
      uploader: json['uploader'] != null
          ? UserModel.fromJson(json['uploader'])
          : null, // Handle null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'cloudUrl': cloudUrl,
      'durationSeconds': durationSeconds,
      'mimeType': mimeType,
    };
  }

  /// Mapper → Domain
  AudioFileEntity toEntity() {
    return AudioFileEntity(
      id: id!,
      fileName: fileName,
      localPath: '', // API model doesn't have local path
      cloudUrl: cloudUrl,
      durationSeconds: durationSeconds,
      mimeType: mimeType,
      uploaderId: uploaderId,
      uploadedAt: uploadedAt,
      username: uploader?.username ?? '', // Handle null uploader
    );
  }

  AudioFileHiveModel toHiveModel() {
    return AudioFileHiveModel(
      id: id!,
      fileName: fileName,
      localPath: '', // API model doesn't have local path
      cloudUrl: cloudUrl,
      durationSeconds: durationSeconds,
      mimeType: mimeType,
      uploaderId: uploaderId,
      uploadedAt: uploadedAt,
    );
  }
}

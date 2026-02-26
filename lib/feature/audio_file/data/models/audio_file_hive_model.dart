import 'package:hive/hive.dart';

part 'audio_file_hive_model.g.dart';

/// syncStatus:
/// 0 = synced
/// 1 = pendingUpload (recorded offline, not yet on server)
/// 2 = pendingUpdate (title changed offline)
@HiveType(typeId: 5)
class AudioFileHiveModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String fileName;

  @HiveField(2)
  String localPath;

  @HiveField(3)
  String cloudUrl;

  @HiveField(4)
  int durationSeconds;

  @HiveField(5)
  String mimeType;

  @HiveField(6)
  DateTime uploadedAt;

  @HiveField(7)
  String uploaderId;

  @HiveField(8)
  String? title;

  @HiveField(9)
  int syncStatus;

  AudioFileHiveModel({
    required this.id,
    required this.fileName,
    required this.localPath,
    required this.cloudUrl,
    required this.durationSeconds,
    required this.mimeType,
    required this.uploadedAt,
    required this.uploaderId,
    this.title,
    this.syncStatus = 0,
  });

  AudioFileHiveModel copyWith({
    String? id,
    String? title,
    String? fileName,
    String? localPath,
    String? cloudUrl,
    int? durationSeconds,
    String? mimeType,
    DateTime? uploadedAt,
    String? uploaderId,
    int? syncStatus,
  }) {
    return AudioFileHiveModel(
      id: id ?? this.id,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      cloudUrl: cloudUrl ?? this.cloudUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      mimeType: mimeType ?? this.mimeType,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploaderId: uploaderId ?? this.uploaderId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

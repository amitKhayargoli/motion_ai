import 'package:hive/hive.dart';

part 'audio_file_hive_model.g.dart';

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

  AudioFileHiveModel({
    required this.id,
    required this.fileName,
    required this.localPath,
    required this.cloudUrl,
    required this.durationSeconds,
    required this.mimeType,
    required this.uploadedAt,
    required this.uploaderId,
  });
}

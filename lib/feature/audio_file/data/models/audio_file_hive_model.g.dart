// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_file_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AudioFileHiveModelAdapter extends TypeAdapter<AudioFileHiveModel> {
  @override
  final int typeId = 5;

  @override
  AudioFileHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AudioFileHiveModel(
      id: fields[0] as String,
      fileName: fields[1] as String,
      localPath: fields[2] as String,
      cloudUrl: fields[3] as String,
      durationSeconds: fields[4] as int,
      mimeType: fields[5] as String,
      uploadedAt: fields[6] as DateTime,
      uploaderId: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AudioFileHiveModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fileName)
      ..writeByte(2)
      ..write(obj.localPath)
      ..writeByte(3)
      ..write(obj.cloudUrl)
      ..writeByte(4)
      ..write(obj.durationSeconds)
      ..writeByte(5)
      ..write(obj.mimeType)
      ..writeByte(6)
      ..write(obj.uploadedAt)
      ..writeByte(7)
      ..write(obj.uploaderId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioFileHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

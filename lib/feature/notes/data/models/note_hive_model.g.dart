// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteHiveModelAdapter extends TypeAdapter<NoteHiveModel> {
  @override
  final int typeId = 2;

  @override
  NoteHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteHiveModel(
      id: fields[0] as String,
      workspaceId: fields[1] as String,
      title: fields[2] as String,
      content: fields[3] as String,
      summary: fields[4] as String?,
      createdAt: fields[5] as DateTime?,
      updatedAt: fields[6] as DateTime?,
      syncStatus: fields[7] as int,
      serverId: fields[8] as String?,
      audioFileId: fields[9] as String?,
      type: fields[10] as String?,
      status: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NoteHiveModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.workspaceId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.summary)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.syncStatus)
      ..writeByte(8)
      ..write(obj.serverId)
      ..writeByte(9)
      ..write(obj.audioFileId)
      ..writeByte(10)
      ..write(obj.type)
      ..writeByte(11)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

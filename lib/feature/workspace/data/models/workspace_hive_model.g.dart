// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkspaceHiveModelAdapter extends TypeAdapter<WorkspaceHiveModel> {
  @override
  final int typeId = 20;

  @override
  WorkspaceHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkspaceHiveModel(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WorkspaceHiveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

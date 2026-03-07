// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_thread_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatThreadHiveModelAdapter extends TypeAdapter<ChatThreadHiveModel> {
  @override
  final int typeId = 6;

  @override
  ChatThreadHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatThreadHiveModel(
      id: fields[0] as String,
      workspaceId: fields[1] as String,
      userId: fields[2] as String,
      title: fields[3] as String,
      createdAt: fields[4] as DateTime?,
      updatedAt: fields[5] as DateTime?,
      messages: (fields[6] as List).cast<ChatMessageHiveModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatThreadHiveModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.workspaceId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.messages);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatThreadHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

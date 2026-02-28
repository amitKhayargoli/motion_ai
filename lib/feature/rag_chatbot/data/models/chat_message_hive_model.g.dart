// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatMessageHiveModelAdapter extends TypeAdapter<ChatMessageHiveModel> {
  @override
  final int typeId = 7;

  @override
  ChatMessageHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessageHiveModel(
      id: fields[0] as String,
      threadId: fields[1] as String,
      role: fields[2] as String,
      content: fields[3] as String,
      createdAt: fields[4] as DateTime?,
      pending: fields[5] as bool,
      failed: fields[6] as bool,
      notesJson: fields[7] as String?,
      kind: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessageHiveModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.threadId)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.pending)
      ..writeByte(6)
      ..write(obj.failed)
      ..writeByte(7)
      ..write(obj.notesJson)
      ..writeByte(8)
      ..write(obj.kind);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

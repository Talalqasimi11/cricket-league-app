part of 'pending_operation.dart';

// GENERATED CODE - DO NOT MODIFY BY HAND

class PendingOperationAdapter extends TypeAdapter<PendingOperation> {
  @override
  final int typeId = 4;

  @override
  PendingOperation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingOperation(
      id: fields[0] as String,
      operationType: OperationType.values[fields[1] as int],
      entityType: fields[2] as String,
      entityId: fields[3] as int,
      data: (fields[4] as Map<dynamic, dynamic>).cast<String, dynamic>(),
      createdAt: fields[5] as DateTime,
      retryCount: fields[6] as int,
      lastAttempt: fields[7] as DateTime?,
      errorMessage: fields[8] as String?,
      requiresConflictResolution: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PendingOperation obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.operationType.index)
      ..writeByte(2)
      ..write(obj.entityType)
      ..writeByte(3)
      ..write(obj.entityId)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.retryCount)
      ..writeByte(7)
      ..write(obj.lastAttempt)
      ..writeByte(8)
      ..write(obj.errorMessage)
      ..writeByte(9)
      ..write(obj.requiresConflictResolution);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

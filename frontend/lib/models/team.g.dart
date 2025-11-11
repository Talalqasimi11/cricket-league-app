// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TeamAdapter extends TypeAdapter<Team> {
  @override
  final int typeId = 3;

  @override
  Team read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Team(
      id: fields[0] as int,
      teamName: fields[1] as String,
      teamLogoUrl: fields[2] as String?,
      location: fields[3] as String?,
      trophies: fields[4] as int,
      captainPlayerId: fields[5] as int?,
      viceCaptainPlayerId: fields[6] as int?,
      ownerPhone: fields[7] as String?,
      captainPhone: fields[8] as String?,
      ownerImage: fields[9] as String?,
      captainImage: fields[10] as String?,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Team obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.teamName)
      ..writeByte(2)
      ..write(obj.teamLogoUrl)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.trophies)
      ..writeByte(5)
      ..write(obj.captainPlayerId)
      ..writeByte(6)
      ..write(obj.viceCaptainPlayerId)
      ..writeByte(7)
      ..write(obj.ownerPhone)
      ..writeByte(8)
      ..write(obj.captainPhone)
      ..writeByte(9)
      ..write(obj.ownerImage)
      ..writeByte(10)
      ..write(obj.captainImage)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

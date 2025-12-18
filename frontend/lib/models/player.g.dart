// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 4;

  @override
  Player read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Player(
      id: fields[0] as String,
      name: fields[1] as String,
      role: fields[2] as String,
      imageUrl: fields[3] as String?,
      selected: fields[4] as bool,
      runs: fields[5] as int,
      wickets: fields[6] as int,
      battingAverage: fields[7] as double,
      strikeRate: fields[8] as double,
      matchesPlayed: fields[9] as int,
      hundreds: fields[10] as int,
      fifties: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.selected)
      ..writeByte(5)
      ..write(obj.runs)
      ..writeByte(6)
      ..write(obj.wickets)
      ..writeByte(7)
      ..write(obj.battingAverage)
      ..writeByte(8)
      ..write(obj.strikeRate)
      ..writeByte(9)
      ..write(obj.matchesPlayed)
      ..writeByte(10)
      ..write(obj.hundreds)
      ..writeByte(11)
      ..write(obj.fifties);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
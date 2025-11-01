part of 'player.dart';

// GENERATED CODE - DO NOT MODIFY BY HAND

class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 0;

  @override
  Player read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Player(
      id: fields[0] as int,
      playerName: fields[1] as String,
      playerRole: fields[2] as String,
      playerImageUrl: fields[3] as String?,
      runs: fields[4] as int,
      matchesPlayed: fields[5] as int,
      hundreds: fields[6] as int,
      fifties: fields[7] as int,
      battingAverage: fields[8] as double,
      strikeRate: fields[9] as double,
      wickets: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.playerName)
      ..writeByte(2)
      ..write(obj.playerRole)
      ..writeByte(3)
      ..write(obj.playerImageUrl)
      ..writeByte(4)
      ..write(obj.runs)
      ..writeByte(5)
      ..write(obj.matchesPlayed)
      ..writeByte(6)
      ..write(obj.hundreds)
      ..writeByte(7)
      ..write(obj.fifties)
      ..writeByte(8)
      ..write(obj.battingAverage)
      ..writeByte(9)
      ..write(obj.strikeRate)
      ..writeByte(10)
      ..write(obj.wickets);
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

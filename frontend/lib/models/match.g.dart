part of 'match.dart';

// GENERATED CODE - DO NOT MODIFY BY HAND

class MatchAdapter extends TypeAdapter<Match> {
  @override
  final int typeId = 1;

  @override
  Match read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Match(
      id: fields[0] as int,
      tournamentId: fields[1] as int,
      team1Id: fields[2] as int,
      team2Id: fields[3] as int,
      team1Name: fields[4] as String,
      team2Name: fields[5] as String,
      status: fields[6] as String,
      scheduledTime: fields[7] as DateTime,
      venue: fields[8] as String?,
      overs: fields[9] as int,
      team1Score: fields[10] as int?,
      team1Wickets: fields[11] as int?,
      team2Score: fields[12] as int?,
      team2Wickets: fields[13] as int?,
      winnerId: fields[14] as String?,
      winnerName: fields[15] as String?,
      result: fields[16] as String?,
      createdAt: fields[17] as DateTime,
      updatedAt: fields[18] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Match obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tournamentId)
      ..writeByte(2)
      ..write(obj.team1Id)
      ..writeByte(3)
      ..write(obj.team2Id)
      ..writeByte(4)
      ..write(obj.team1Name)
      ..writeByte(5)
      ..write(obj.team2Name)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.scheduledTime)
      ..writeByte(8)
      ..write(obj.venue)
      ..writeByte(9)
      ..write(obj.overs)
      ..writeByte(10)
      ..write(obj.team1Score)
      ..writeByte(11)
      ..write(obj.team1Wickets)
      ..writeByte(12)
      ..write(obj.team2Score)
      ..writeByte(13)
      ..write(obj.team2Wickets)
      ..writeByte(14)
      ..write(obj.winnerId)
      ..writeByte(15)
      ..write(obj.winnerName)
      ..writeByte(16)
      ..write(obj.result)
      ..writeByte(17)
      ..write(obj.createdAt)
      ..writeByte(18)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

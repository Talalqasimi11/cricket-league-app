import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'match.g.dart';

@HiveType(typeId: 1)
class Match extends HiveObject {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final int tournamentId;
  @HiveField(2)
  final int team1Id;
  @HiveField(3)
  final int team2Id;
  @HiveField(4)
  final String team1Name;
  @HiveField(5)
  final String team2Name;
  @HiveField(6)
  final String status; // scheduled, live, completed, cancelled
  @HiveField(7)
  final DateTime scheduledTime;
  @HiveField(8)
  final String? venue;
  @HiveField(9)
  final int overs;
  @HiveField(10)
  final int? team1Score;
  @HiveField(11)
  final int? team1Wickets;
  @HiveField(12)
  final int? team2Score;
  @HiveField(13)
  final int? team2Wickets;
  @HiveField(14)
  final String? winnerId;
  @HiveField(15)
  final String? winnerName;
  @HiveField(16)
  final String? result;
  @HiveField(17)
  final DateTime createdAt;
  @HiveField(18)
  final DateTime updatedAt;

  Match({
    required this.id,
    required this.tournamentId,
    required this.team1Id,
    required this.team2Id,
    required this.team1Name,
    required this.team2Name,
    required this.status,
    required this.scheduledTime,
    this.venue,
    required this.overs,
    this.team1Score,
    this.team1Wickets,
    this.team2Score,
    this.team2Wickets,
    this.winnerId,
    this.winnerName,
    this.result,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as int? ?? 0,
      tournamentId: json['tournament_id'] as int? ?? 0,
      team1Id: json['team1_id'] as int? ?? 0,
      team2Id: json['team2_id'] as int? ?? 0,
      team1Name: json['team1_name'] as String? ?? '',
      team2Name: json['team2_name'] as String? ?? '',
      status: json['status'] as String? ?? 'scheduled',
      scheduledTime:
          DateTime.tryParse(json['scheduled_time'] as String? ?? '') ??
          DateTime.now(),
      venue: json['venue'] as String?,
      overs: json['overs'] as int? ?? 20,
      team1Score: json['team1_score'] as int?,
      team1Wickets: json['team1_wickets'] as int?,
      team2Score: json['team2_score'] as int?,
      team2Wickets: json['team2_wickets'] as int?,
      winnerId: json['winner_id']?.toString(),
      winnerName: json['winner_name'] as String?,
      result: json['result'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'team1_id': team1Id,
      'team2_id': team2Id,
      'team1_name': team1Name,
      'team2_name': team2Name,
      'status': status,
      'scheduled_time': scheduledTime.toIso8601String(),
      'venue': venue,
      'overs': overs,
      'team1_score': team1Score,
      'team1_wickets': team1Wickets,
      'team2_score': team2Score,
      'team2_wickets': team2Wickets,
      'winner_id': winnerId,
      'winner_name': winnerName,
      'result': result,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Match copyWith({
    int? id,
    int? tournamentId,
    int? team1Id,
    int? team2Id,
    String? team1Name,
    String? team2Name,
    String? status,
    DateTime? scheduledTime,
    String? venue,
    int? overs,
    int? team1Score,
    int? team1Wickets,
    int? team2Score,
    int? team2Wickets,
    String? winnerId,
    String? winnerName,
    String? result,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Match(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      venue: venue ?? this.venue,
      overs: overs ?? this.overs,
      team1Score: team1Score ?? this.team1Score,
      team1Wickets: team1Wickets ?? this.team1Wickets,
      team2Score: team2Score ?? this.team2Score,
      team2Wickets: team2Wickets ?? this.team2Wickets,
      winnerId: winnerId ?? this.winnerId,
      winnerName: winnerName ?? this.winnerName,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isLive => status == 'live';
  bool get isCompleted => status == 'completed';
  bool get isScheduled => status == 'scheduled';
  String get formattedDate =>
      DateFormat('MMM dd, yyyy - HH:mm').format(scheduledTime);

  @override
  String toString() {
    return 'Match(id: $id, $team1Name vs $team2Name, status: $status)';
  }
}

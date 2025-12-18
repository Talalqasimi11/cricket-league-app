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
      // SAFE PARSING: Handles both "1" (String) and 1 (Int)
      id: _parseInt(json['id']),
      tournamentId: _parseInt(json['tournament_id']),
      team1Id: _parseInt(json['team1_id']),
      team2Id: _parseInt(json['team2_id']),
      team1Name: json['team1_name']?.toString() ?? '',
      team2Name: json['team2_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'scheduled',
      scheduledTime: _parseDate(json['scheduled_time']),
      venue: json['venue']?.toString(),
      overs: _parseInt(json['overs'], defaultValue: 20),
      team1Score: _parseIntNullable(json['team1_score']),
      team1Wickets: _parseIntNullable(json['team1_wickets']),
      team2Score: _parseIntNullable(json['team2_score']),
      team2Wickets: _parseIntNullable(json['team2_wickets']),
      winnerId: json['winner_id']?.toString(),
      winnerName: json['winner_name']?.toString(),
      result: json['result']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  factory Match.fromTournamentMatch(Map<String, dynamic> json) {
    return Match(
      id: _parseInt(json['id']),
      tournamentId: _parseInt(json['tournament_id']),
      team1Id: _parseInt(json['team1_id']),
      team2Id: _parseInt(json['team2_id']),
      team1Name: json['team1_name']?.toString() ?? 'Team 1',
      team2Name: json['team2_name']?.toString() ?? 'Team 2',
      status: json['status']?.toString() ?? 'scheduled',
      scheduledTime: _parseDate(json['match_date']),
      venue: json['location']?.toString(),
      overs: 20,
      winnerId: json['winner_id']?.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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

  // --- HELPER METHODS ---

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      if (value.isEmpty) return null;
      return int.tryParse(value);
    }
    return null;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  bool get isLive => status.toLowerCase() == 'live';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isScheduled => status.toLowerCase() == 'scheduled';

  String get formattedDate =>
      DateFormat('MMM dd, yyyy - HH:mm').format(scheduledTime);

  @override
  String toString() {
    return 'Match(id: $id, $team1Name vs $team2Name, status: $status)';
  }
}

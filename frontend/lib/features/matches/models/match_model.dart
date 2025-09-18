// lib/features/matches/models/match_model.dart

class MatchModel {
  final String id;
  final String teamA;
  final String teamB;
  final String status; // "planned" | "live" | "completed"
  final DateTime? scheduledAt;
  final String creatorId;
  final int runs;
  final int wickets;
  final double overs;

  MatchModel({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.status,
    this.scheduledAt,
    required this.creatorId,
    this.runs = 0,
    this.wickets = 0,
    this.overs = 0.0,
  });

  factory MatchModel.fromMap(Map<String, dynamic> m) {
    DateTime? scheduled;
    if (m['scheduled_at'] != null) {
      try {
        scheduled = DateTime.parse(m['scheduled_at'] as String);
      } catch (_) {
        scheduled = m['scheduled_at'] is DateTime ? m['scheduled_at'] as DateTime : null;
      }
    }

    return MatchModel(
      id: m['id'].toString(),
      teamA: m['team_a']?.toString() ?? 'Team A',
      teamB: m['team_b']?.toString() ?? 'Team B',
      status: m['status']?.toString() ?? 'planned',
      scheduledAt: scheduled,
      creatorId: m['creator_id']?.toString() ?? '',
      runs: (m['runs'] is num) ? (m['runs'] as num).toInt() : int.tryParse('${m['runs']}') ?? 0,
      wickets: (m['wickets'] is num)
          ? (m['wickets'] as num).toInt()
          : int.tryParse('${m['wickets']}') ?? 0,
      overs: (m['overs'] is num)
          ? (m['overs'] as num).toDouble()
          : double.tryParse('${m['overs']}') ?? 0.0,
    );
  }

  MatchModel copyWith({
    String? id,
    String? teamA,
    String? teamB,
    String? status,
    DateTime? scheduledAt,
    String? creatorId,
    int? runs,
    int? wickets,
    double? overs,
  }) {
    return MatchModel(
      id: id ?? this.id,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      creatorId: creatorId ?? this.creatorId,
      runs: runs ?? this.runs,
      wickets: wickets ?? this.wickets,
      overs: overs ?? this.overs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'team_a': teamA,
      'team_b': teamB,
      'status': status,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'creator_id': creatorId,
      'runs': runs,
      'wickets': wickets,
      'overs': overs,
    };
  }
}

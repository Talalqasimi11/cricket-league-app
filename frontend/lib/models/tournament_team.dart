class TournamentTeam {
  final int id;
  final int tournamentId;
  final String tournamentName;
  final int teamId;
  final String teamName;
  final String status; // registered, rejected, cancelled
  final int registrationFee;
  final bool paymentDone;
  final DateTime registeredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TournamentTeam({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.teamId,
    required this.teamName,
    required this.status,
    required this.registrationFee,
    required this.paymentDone,
    required this.registeredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TournamentTeam.fromJson(Map<String, dynamic> json) {
    return TournamentTeam(
      id: json['id'] as int? ?? 0,
      tournamentId: json['tournament_id'] as int? ?? 0,
      tournamentName: json['tournament_name'] as String? ?? '',
      teamId: json['team_id'] as int? ?? 0,
      teamName: json['team_name'] as String? ?? '',
      status: json['status'] as String? ?? 'registered',
      registrationFee: json['registration_fee'] as int? ?? 0,
      paymentDone: json['payment_done'] as bool? ?? false,
      registeredAt:
          DateTime.tryParse(json['registered_at'] as String? ?? '') ??
          DateTime.now(),
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
      'tournament_name': tournamentName,
      'team_id': teamId,
      'team_name': teamName,
      'status': status,
      'registration_fee': registrationFee,
      'payment_done': paymentDone,
      'registered_at': registeredAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isRegistered => status == 'registered';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
}

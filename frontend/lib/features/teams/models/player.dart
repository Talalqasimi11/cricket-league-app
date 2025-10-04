class Player {
  final int id;
  final String playerName;
  final String playerRole;
  final int runs;
  final int matchesPlayed;
  final int hundreds;
  final int fifties;
  final double battingAverage;
  final double strikeRate;
  final int wickets;

  Player({
    required this.id,
    required this.playerName,
    required this.playerRole,
    required this.runs,
    required this.matchesPlayed,
    required this.hundreds,
    required this.fifties,
    required this.battingAverage,
    required this.strikeRate,
    required this.wickets,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      playerName: json['player_name'],
      playerRole: json['player_role'],
      runs: json['runs'] ?? 0,
      matchesPlayed: json['matches_played'] ?? 0,
      hundreds: json['hundreds'] ?? 0,
      fifties: json['fifties'] ?? 0,
      battingAverage: (json['batting_average'] ?? 0).toDouble(),
      strikeRate: (json['strike_rate'] ?? 0).toDouble(),
      wickets: json['wickets'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player_name': playerName,
      'player_role': playerRole,
      'runs': runs,
      'matches_played': matchesPlayed,
      'hundreds': hundreds,
      'fifties': fifties,
      'batting_average': battingAverage,
      'strike_rate': strikeRate,
      'wickets': wickets,
    };
  }
}

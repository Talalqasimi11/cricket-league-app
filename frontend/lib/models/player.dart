class Player {
  final String id;
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
      id: json['id'] as String,
      playerName: json['playerName'] as String,
      playerRole: json['playerRole'] as String,
      runs: json['runs'] as int,
      matchesPlayed: json['matchesPlayed'] as int,
      hundreds: json['hundreds'] as int,
      fifties: json['fifties'] as int,
      battingAverage: (json['battingAverage'] as num).toDouble(),
      strikeRate: (json['strikeRate'] as num).toDouble(),
      wickets: json['wickets'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'playerName': playerName,
    'playerRole': playerRole,
    'runs': runs,
    'matchesPlayed': matchesPlayed,
    'hundreds': hundreds,
    'fifties': fifties,
    'battingAverage': battingAverage,
    'strikeRate': strikeRate,
    'wickets': wickets,
  };

  Player copyWith({
    String? id,
    String? playerName,
    String? playerRole,
    int? runs,
    int? matchesPlayed,
    int? hundreds,
    int? fifties,
    double? battingAverage,
    double? strikeRate,
    int? wickets,
  }) {
    return Player(
      id: id ?? this.id,
      playerName: playerName ?? this.playerName,
      playerRole: playerRole ?? this.playerRole,
      runs: runs ?? this.runs,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      hundreds: hundreds ?? this.hundreds,
      fifties: fifties ?? this.fifties,
      battingAverage: battingAverage ?? this.battingAverage,
      strikeRate: strikeRate ?? this.strikeRate,
      wickets: wickets ?? this.wickets,
    );
  }
}

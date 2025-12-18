import 'package:hive/hive.dart';

part 'player.g.dart';

@HiveType(typeId: 4)
class Player extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String role;
  @HiveField(3)
  final String? imageUrl;
  @HiveField(4)
  bool selected;
  @HiveField(5)
  final int runs;
  @HiveField(6)
  final int wickets;
  @HiveField(7)
  final double battingAverage;
  @HiveField(8)
  final double strikeRate;
  @HiveField(9)
  final int matchesPlayed;
  @HiveField(10)
  final int hundreds;
  @HiveField(11)
  final int fifties;

  Player({
    required this.id,
    required this.name,
    required this.role,
    this.imageUrl,
    this.selected = false,
    this.runs = 0,
    this.wickets = 0,
    this.battingAverage = 0.0,
    this.strikeRate = 0.0,
    this.matchesPlayed = 0,
    this.hundreds = 0,
    this.fifties = 0,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Unknown Player',
      role: json['role'] as String? ?? 'Unknown',
      imageUrl: json['image_url'] as String?,
      runs: json['runs'] as int? ?? 0,
      wickets: json['wickets'] as int? ?? 0,
      battingAverage: (json['batting_average'] as num?)?.toDouble() ?? 0.0,
      strikeRate: (json['strike_rate'] as num?)?.toDouble() ?? 0.0,
      matchesPlayed: json['matches_played'] as int? ?? 0,
      hundreds: json['hundreds'] as int? ?? 0,
      fifties: json['fifties'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'image_url': imageUrl,
      'runs': runs,
      'wickets': wickets,
      'batting_average': battingAverage,
      'strike_rate': strikeRate,
      'matches_played': matchesPlayed,
      'hundreds': hundreds,
      'fifties': fifties,
    };
  }
}
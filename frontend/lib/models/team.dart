import 'package:hive/hive.dart';

part 'team.g.dart';

@HiveType(typeId: 3)
class Team extends HiveObject {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String teamName;
  @HiveField(2)
  final String? teamLogoUrl;
  @HiveField(3)
  final String? location;
  @HiveField(4)
  final int trophies;
  @HiveField(5)
  final int? captainPlayerId;
  @HiveField(6)
  final int? viceCaptainPlayerId;
  @HiveField(7)
  final String? ownerPhone;
  @HiveField(8)
  final String? captainPhone;
  @HiveField(9)
  final String? ownerImage;
  @HiveField(10)
  final String? captainImage;
  @HiveField(11)
  final DateTime createdAt;
  @HiveField(12)
  final DateTime updatedAt;

  Team({
    required this.id,
    required this.teamName,
    this.teamLogoUrl,
    this.location,
    required this.trophies,
    this.captainPlayerId,
    this.viceCaptainPlayerId,
    this.ownerPhone,
    this.captainPhone,
    this.ownerImage,
    this.captainImage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as int? ?? 0,
      teamName: json['team_name'] as String? ?? '',
      teamLogoUrl: json['team_logo_url']?.toString(),
      location: json['team_location'] as String?,
      trophies: json['trophies'] as int? ?? 0,
      captainPlayerId: json['captain_player_id'] as int?,
      viceCaptainPlayerId: json['vice_captain_player_id'] as int?,
      ownerPhone: json['owner_phone']?.toString(),
      captainPhone: json['captain_phone']?.toString(),
      ownerImage: json['owner_image']?.toString(),
      captainImage: json['captain_image']?.toString(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_name': teamName,
      'team_logo_url': teamLogoUrl,
      'team_location': location,
      'trophies': trophies,
      'captain_player_id': captainPlayerId,
      'vice_captain_player_id': viceCaptainPlayerId,
      'owner_phone': ownerPhone,
      'captain_phone': captainPhone,
      'owner_image': ownerImage,
      'captain_image': captainImage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Team copyWith({
    int? id,
    String? teamName,
    String? teamLogoUrl,
    String? location,
    int? trophies,
    int? captainPlayerId,
    int? viceCaptainPlayerId,
    String? ownerPhone,
    String? captainPhone,
    String? ownerImage,
    String? captainImage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id ?? this.id,
      teamName: teamName ?? this.teamName,
      teamLogoUrl: teamLogoUrl ?? this.teamLogoUrl,
      location: location ?? this.location,
      trophies: trophies ?? this.trophies,
      captainPlayerId: captainPlayerId ?? this.captainPlayerId,
      viceCaptainPlayerId: viceCaptainPlayerId ?? this.viceCaptainPlayerId,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      captainPhone: captainPhone ?? this.captainPhone,
      ownerImage: ownerImage ?? this.ownerImage,
      captainImage: captainImage ?? this.captainImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Team(id: $id, name: $teamName, trophies: $trophies)';
  }
}

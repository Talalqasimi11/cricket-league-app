import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

part 'team.g.dart';

@HiveType(typeId: 3)
class Team extends HiveObject {
  @HiveField(0)
  final String id; // Changed to String for better API compatibility
  
  @HiveField(1)
  final String teamName;
  
  @HiveField(2)
  final String? teamLogoUrl;
  
  @HiveField(3)
  final String? location;
  
  @HiveField(4)
  final int trophies;
  
  @HiveField(5)
  final String? captainPlayerId; // Changed to String
  
  @HiveField(6)
  final String? viceCaptainPlayerId; // Changed to String
  
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

  @HiveField(13)
  final int matchesPlayed; // Added missing fields
  
  @HiveField(14)
  final int matchesWon;

  Team({
    required this.id,
    required this.teamName,
    this.teamLogoUrl,
    this.location,
    this.trophies = 0,
    this.captainPlayerId,
    this.viceCaptainPlayerId,
    this.ownerPhone,
    this.captainPhone,
    this.ownerImage,
    this.captainImage,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.matchesPlayed = 0,
    this.matchesWon = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    // Validation
    if (id.isEmpty) {
      debugPrint('Warning: Team created with empty id');
    }
    if (teamName.isEmpty) {
      debugPrint('Warning: Team created with empty teamName');
    }
    if (trophies < 0 || matchesPlayed < 0 || matchesWon < 0) {
      debugPrint('Warning: Team created with negative values');
    }
    if (matchesWon > matchesPlayed) {
      debugPrint('Warning: Matches won exceeds matches played');
    }
  }

  // Safe parsing helpers
  static String _safeString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    final str = value.toString().trim();
    return str.isNotEmpty ? str : defaultValue;
  }

  static String? _safeNullableString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isNotEmpty ? str : null;
  }

  static int _safeInt(dynamic value, int defaultValue) {
    try {
      if (value == null) return defaultValue;
      if (value is int) return value.clamp(0, 2147483647);
      if (value is double) return value.toInt().clamp(0, 2147483647);
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        return parsed?.clamp(0, 2147483647) ?? defaultValue;
      }
      return defaultValue;
    } catch (e) {
      debugPrint('Error converting to int: $e, value: $value');
      return defaultValue;
    }
  }

  static DateTime _safeParseDateTime(dynamic value, DateTime defaultValue) {
    if (value == null) return defaultValue;
    
    try {
      if (value is DateTime) return value;
      if (value is String) {
        if (value.isEmpty) return defaultValue;
        return DateTime.parse(value);
      }
      return defaultValue;
    } catch (e) {
      debugPrint('Error parsing DateTime: $e, value: $value');
      return defaultValue;
    }
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    try {
      final now = DateTime.now();
      
      return Team(
        id: _safeString(json['id'] ?? json['team_id'], '0'),
        teamName: _safeString(
          json['team_name'] ?? json['name'],
          'Unknown Team',
        ),
        teamLogoUrl: _safeNullableString(
          json['team_logo_url'] ?? json['logo_url'] ?? json['team_logo'],
        ),
        location: _safeNullableString(
          json['team_location'] ?? json['location'],
        ),
        trophies: _safeInt(json['trophies'], 0),
        captainPlayerId: _safeNullableString(
          json['captain_player_id'] ?? json['captain_id'],
        ),
        viceCaptainPlayerId: _safeNullableString(
          json['vice_captain_player_id'] ?? json['vice_captain_id'],
        ),
        ownerPhone: _safeNullableString(json['owner_phone']),
        captainPhone: _safeNullableString(json['captain_phone']),
        ownerImage: _safeNullableString(json['owner_image']),
        captainImage: _safeNullableString(json['captain_image']),
        createdAt: _safeParseDateTime(json['created_at'], now),
        updatedAt: _safeParseDateTime(json['updated_at'], now),
        matchesPlayed: _safeInt(json['matches_played'], 0),
        matchesWon: _safeInt(json['matches_won'], 0),
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing Team from JSON: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('JSON data: $json');
      
      // Return fallback team
      return Team(
        id: json['id']?.toString() ?? '0',
        teamName: 'Error Loading Team',
      );
    }
  }

  Map<String, dynamic> toJson() {
    try {
      return {
        'id': id,
        'team_name': teamName,
        if (teamLogoUrl != null && teamLogoUrl!.isNotEmpty)
          'team_logo_url': teamLogoUrl,
        if (location != null && location!.isNotEmpty)
          'team_location': location,
        'trophies': trophies,
        if (captainPlayerId != null && captainPlayerId!.isNotEmpty)
          'captain_player_id': captainPlayerId,
        if (viceCaptainPlayerId != null && viceCaptainPlayerId!.isNotEmpty)
          'vice_captain_player_id': viceCaptainPlayerId,
        if (ownerPhone != null && ownerPhone!.isNotEmpty)
          'owner_phone': ownerPhone,
        if (captainPhone != null && captainPhone!.isNotEmpty)
          'captain_phone': captainPhone,
        if (ownerImage != null && ownerImage!.isNotEmpty)
          'owner_image': ownerImage,
        if (captainImage != null && captainImage!.isNotEmpty)
          'captain_image': captainImage,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'matches_played': matchesPlayed,
        'matches_won': matchesWon,
      };
    } catch (e) {
      debugPrint('Error serializing Team to JSON: $e');
      rethrow;
    }
  }

  Team copyWith({
    String? id,
    String? teamName,
    String? teamLogoUrl,
    bool clearTeamLogoUrl = false,
    String? location,
    bool clearLocation = false,
    int? trophies,
    String? captainPlayerId,
    bool clearCaptainPlayerId = false,
    String? viceCaptainPlayerId,
    bool clearViceCaptainPlayerId = false,
    String? ownerPhone,
    bool clearOwnerPhone = false,
    String? captainPhone,
    bool clearCaptainPhone = false,
    String? ownerImage,
    bool clearOwnerImage = false,
    String? captainImage,
    bool clearCaptainImage = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? matchesPlayed,
    int? matchesWon,
  }) {
    return Team(
      id: id ?? this.id,
      teamName: teamName ?? this.teamName,
      teamLogoUrl: clearTeamLogoUrl ? null : (teamLogoUrl ?? this.teamLogoUrl),
      location: clearLocation ? null : (location ?? this.location),
      trophies: trophies ?? this.trophies,
      captainPlayerId: clearCaptainPlayerId
          ? null
          : (captainPlayerId ?? this.captainPlayerId),
      viceCaptainPlayerId: clearViceCaptainPlayerId
          ? null
          : (viceCaptainPlayerId ?? this.viceCaptainPlayerId),
      ownerPhone: clearOwnerPhone ? null : (ownerPhone ?? this.ownerPhone),
      captainPhone: clearCaptainPhone ? null : (captainPhone ?? this.captainPhone),
      ownerImage: clearOwnerImage ? null : (ownerImage ?? this.ownerImage),
      captainImage: clearCaptainImage ? null : (captainImage ?? this.captainImage),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      matchesWon: matchesWon ?? this.matchesWon,
    );
  }

  // Convenience getters
  double get winPercentage {
    if (matchesPlayed == 0) return 0.0;
    return (matchesWon / matchesPlayed) * 100;
  }

  int get matchesLost {
    return matchesPlayed - matchesWon;
  }

  bool get hasLogo => teamLogoUrl != null && teamLogoUrl!.isNotEmpty;
  
  bool get hasLocation => location != null && location!.isNotEmpty;
  
  bool get hasCaptain => captainPlayerId != null && captainPlayerId!.isNotEmpty;
  
  bool get hasViceCaptain =>
      viceCaptainPlayerId != null && viceCaptainPlayerId!.isNotEmpty;

  bool get hasOwnerPhone => ownerPhone != null && ownerPhone!.isNotEmpty;
  
  bool get hasCaptainPhone => captainPhone != null && captainPhone!.isNotEmpty;

  String get displayName => teamName.isNotEmpty ? teamName : 'Unknown Team';

  String get displayLocation => location ?? 'Unknown Location';

  // Get masked phone numbers for privacy
  String? get maskedOwnerPhone {
    if (ownerPhone == null || ownerPhone!.isEmpty) return null;
    if (ownerPhone!.length <= 4) return ownerPhone;
    return '****${ownerPhone!.substring(ownerPhone!.length - 4)}';
  }

  String? get maskedCaptainPhone {
    if (captainPhone == null || captainPhone!.isEmpty) return null;
    if (captainPhone!.length <= 4) return captainPhone;
    return '****${captainPhone!.substring(captainPhone!.length - 4)}';
  }

  // Validation method
  List<String> validate() {
    final issues = <String>[];
    
    if (id.isEmpty) {
      issues.add('Team ID is empty');
    }
    if (teamName.isEmpty || teamName.length < 2) {
      issues.add('Team name is invalid');
    }
    if (trophies < 0) {
      issues.add('Trophies cannot be negative');
    }
    if (matchesPlayed < 0) {
      issues.add('Matches played cannot be negative');
    }
    if (matchesWon < 0) {
      issues.add('Matches won cannot be negative');
    }
    if (matchesWon > matchesPlayed) {
      issues.add('Matches won cannot exceed matches played');
    }
    
    return issues;
  }

  bool get isValid => validate().isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Team && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Team(id: $id, name: $teamName, location: $location, '
           'trophies: $trophies, matches: $matchesPlayed, won: $matchesWon, '
           'winRate: ${winPercentage.toStringAsFixed(1)}%)';
  }

  // Create summary string for display
  String get summary {
    final parts = <String>[
      displayName,
      if (hasLocation) displayLocation,
      'Trophies: $trophies',
      if (matchesPlayed > 0) 'Win Rate: ${winPercentage.toStringAsFixed(1)}%',
    ];
    return parts.join(' • ');
  }
}
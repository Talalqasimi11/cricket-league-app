import 'package:flutter/foundation.dart';
import '../../models/team.dart';
import 'base_repository.dart';
import 'hive_service.dart';

/// Repository for Team entities with local storage operations
class TeamRepository extends BaseRepository<Team> {
  TeamRepository(HiveService hiveService)
      : super(hiveService, HiveService.boxTeams);

  /// Get all teams sorted by creation date (newest first)
  @override
  List<Team> getAll() {
    final teams = super.getAll();
    teams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return teams;
  }

  /// Get team by ID
  @override
  Team? getById(int id) {
    return super.getById(id);
  }

  /// Save team
  Future<void> saveTeam(Team team) async {
    await save(team);
  }

  /// Update team
  Future<void> updateTeam(int key, Team team) async {
    await update(key, team);
  }

  /// Get teams by location
  List<Team> getByLocation(String location) {
    return filter((team) =>
        team.location?.toLowerCase().contains(location.toLowerCase()) ?? false);
  }

  /// Search teams by name
  List<Team> searchByName(String query) {
    return filter((team) =>
        team.teamName.toLowerCase().contains(query.toLowerCase()));
  }

  /// Get teams with trophies above threshold
  List<Team> getByMinTrophies(int minTrophies) {
    return filter((team) => team.trophies >= minTrophies);
  }

  /// Get teams sorted by trophies (descending)
  List<Team> getTopTeamsByTrophies({int limit = 10}) {
    final teams = getAll();
    teams.sort((a, b) => b.trophies.compareTo(a.trophies));
    return teams.take(limit).toList();
  }

  /// Get teams created within date range
  List<Team> getByDateRange(DateTime start, DateTime end) {
    return filter((team) {
      return team.createdAt.isAfter(start.subtract(const Duration(days: 1))) &&
             team.createdAt.isBefore(end.add(const Duration(days: 1)));
    });
  }

  /// Get teams with captain
  List<Team> getTeamsWithCaptain() {
    return filter((team) => team.captainPlayerId != null);
  }

  /// Get team by captain ID
  Team? getByCaptainId(int captainId) {
    return findFirst((team) => team.captainPlayerId == captainId);
  }

  /// Get team by vice captain ID
  Team? getByViceCaptainId(int viceCaptainId) {
    return findFirst((team) => team.viceCaptainPlayerId == viceCaptainId);
  }

  /// Sync team from server (merge/update existing)
  Future<void> syncFromServer(Team serverTeam) async {
    try {
      final existing = getById(serverTeam.id);
      if (existing != null) {
        // Update existing if server version is newer
        if (serverTeam.updatedAt.isAfter(existing.updatedAt)) {
          final key = keys.firstWhere((k) => getByKey(k)?.id == serverTeam.id);
          await update(key, serverTeam);
        }
      } else {
        // Add new team
        await save(serverTeam);
      }
    } catch (e) {
      debugPrint('[TeamRepository] Sync error: $e');
      // Add as new if sync fails
      await save(serverTeam);
    }
  }

  /// Bulk sync teams from server
  Future<void> syncFromServerList(List<Team> serverTeams) async {
    for (final team in serverTeams) {
      await syncFromServer(team);
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    final all = getAll();
    final totalTrophies = all.fold<int>(0, (sum, team) => sum + team.trophies);
    final avgTrophies = all.isEmpty ? 0 : totalTrophies / all.length;

    return {
      'total': all.length,
      'withCaptain': all.where((t) => t.captainPlayerId != null).length,
      'withLocation': all.where((t) => t.location != null).length,
      'totalTrophies': totalTrophies,
      'averageTrophies': avgTrophies.round(),
    };
  }
}

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
    final teams = List<Team>.of(super.getAll()); // avoid mutating base list
    teams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return teams;
  }

  /// Keep BaseRepository getById signature for compatibility (likely int).
  /// Do not use this for domain String IDs. Use getByTeamId(String) below.
  @override
  Team? getById(int id) {
    return super.getById(id);
  }

  /// Save team
  Future<void> saveTeam(Team team) async {
    await save(team);
  }

  /// Update team by Hive key (not domain id)
  Future<void> updateTeam(int key, Team team) async {
    await update(key, team);
  }

  /// Get team by domain id (String)
  Team? getByTeamId(String id) {
    return findFirst((t) => t.id == id);
  }

  /// Get teams by location (case-insensitive, guarded)
  List<Team> getByLocation(String location) {
    final q = location.trim().toLowerCase();
    if (q.isEmpty) return [];
    return filter((team) => (team.location ?? '').toLowerCase().contains(q));
  }

  /// Search teams by name (case-insensitive, guarded)
  List<Team> searchByName(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return filter((team) => team.teamName.toLowerCase().contains(q));
  }

  /// Get teams with trophies above threshold
  List<Team> getByMinTrophies(int minTrophies) {
    return filter((team) => team.trophies >= minTrophies);
  }

  /// Get teams sorted by trophies (descending)
  List<Team> getTopTeamsByTrophies({int limit = 10}) {
    if (limit <= 0) return <Team>[];
    final teams = List<Team>.of(getAll());
    teams.sort((a, b) => b.trophies.compareTo(a.trophies));
    return teams.take(limit).toList();
  }

  /// Get teams created within date range (inclusive, UTC-normalized)
  List<Team> getByDateRange(DateTime start, DateTime end) {
    final s = start.toUtc();
    final e = end.toUtc();
    return filter((team) {
      final d = team.createdAt.toUtc();
      return d.compareTo(s) >= 0 && d.compareTo(e) <= 0;
    });
  }

  /// Get teams with captain
  List<Team> getTeamsWithCaptain() {
    return filter((team) => (team.captainPlayerId?.isNotEmpty ?? false));
  }

  /// Get team by captain ID (String)
  Team? getByCaptainId(String captainId) {
    return findFirst((team) => team.captainPlayerId == captainId);
  }

  /// Get team by vice captain ID (String)
  Team? getByViceCaptainId(String viceCaptainId) {
    return findFirst((team) => team.viceCaptainPlayerId == viceCaptainId);
  }

  /// Sync team from server (merge/update existing)
  Future<void> syncFromServer(Team serverTeam) async {
    try {
      // Find by domain id (String) to avoid int/String mismatch
      final existing = getByTeamId(serverTeam.id);
      if (existing == null) {
        await save(serverTeam);
        return;
      }

      // updatedAt/createdAt assumed non-nullable; compare directly
      if (serverTeam.updatedAt.isAfter(existing.updatedAt)) {
        final key = _findKeyByTeamId(serverTeam.id);
        if (key != null) {
          await update(key, serverTeam);
        } else {
          // Fallback if we can't resolve Hive key
          await save(serverTeam);
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[TeamRepository] Sync error: $e\n$st');
      }
      // Only save if not already present (avoid dupes)
      final exists = getByTeamId(serverTeam.id) != null;
      if (!exists) {
        await save(serverTeam);
      }
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
    final avgTrophies = all.isEmpty ? 0 : (totalTrophies / all.length).round();

    return {
      'total': all.length,
      'withCaptain': all.where((t) => (t.captainPlayerId?.isNotEmpty ?? false)).length,
      'withLocation': all.where((t) => (t.location ?? '').trim().isNotEmpty).length,
      'totalTrophies': totalTrophies,
      'averageTrophies': avgTrophies,
    };
  }

  /// Resolve Hive key (int) from domain id (String)
  int? _findKeyByTeamId(String id) {
    for (final dynamic k in keys) {
      final t = getByKey(k);
      if (t?.id == id) return k as int?;
    }
    return null;
  }
}
import 'package:flutter/foundation.dart';
import '../../models/match.dart';
import 'base_repository.dart';
import 'hive_service.dart';

/// Repository for Match entities with local storage operations
class MatchRepository extends BaseRepository<Match> {
  MatchRepository(HiveService hiveService)
      : super(hiveService, HiveService.boxMatches);

  /// Get all matches sorted by scheduled time (newest first)
  @override
  List<Match> getAll() {
    final matches = super.getAll();
    matches.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
    return matches;
  }

  /// Get match by ID
  @override
  Match? getById(int id) {
    return super.getById(id);
  }

  /// Save match
  Future<void> saveMatch(Match match) async {
    await save(match);
  }

  /// Update match
  Future<void> updateMatch(int key, Match match) async {
    await update(key, match);
  }

  /// Get matches by status
  List<Match> getByStatus(String status) {
    return filter((match) => match.status == status);
  }

  /// Get live matches
  List<Match> getLiveMatches() {
    return filter((match) => match.isLive);
  }

  /// Get completed matches
  List<Match> getCompletedMatches() {
    return filter((match) => match.isCompleted);
  }

  /// Get scheduled matches
  List<Match> getScheduledMatches() {
    return filter((match) => match.isScheduled);
  }

  /// Get matches by tournament ID
  List<Match> getByTournamentId(int tournamentId) {
    return filter((match) => match.tournamentId == tournamentId);
  }

  /// Get matches by team ID (either team1 or team2)
  List<Match> getByTeamId(int teamId) {
    return filter((match) =>
        match.team1Id == teamId || match.team2Id == teamId);
  }

  /// Get matches within date range
  List<Match> getByDateRange(DateTime start, DateTime end) {
    return filter((match) {
      return match.scheduledTime.isAfter(start.subtract(const Duration(days: 1))) &&
             match.scheduledTime.isBefore(end.add(const Duration(days: 1)));
    });
  }

  /// Get upcoming matches (scheduled in the future)
  List<Match> getUpcomingMatches() {
    final now = DateTime.now();
    return filter((match) =>
        match.scheduledTime.isAfter(now) && match.status == 'scheduled');
  }

  /// Get recent matches (completed within last N days)
  List<Match> getRecentMatches(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return filter((match) =>
        match.status == 'completed' && match.updatedAt.isAfter(cutoff));
  }

  /// Search matches by team name
  List<Match> searchByTeamName(String query) {
    return filter((match) =>
        match.team1Name.toLowerCase().contains(query.toLowerCase()) ||
        match.team2Name.toLowerCase().contains(query.toLowerCase()));
  }

  /// Sync match from server (merge/update existing)
  Future<void> syncFromServer(Match serverMatch) async {
    try {
      final existing = getById(serverMatch.id);
      if (existing != null) {
        // Update existing if server version is newer
        if (serverMatch.updatedAt.isAfter(existing.updatedAt)) {
          final key = keys.firstWhere((k) => getByKey(k)?.id == serverMatch.id);
          await update(key, serverMatch);
        }
      } else {
        // Add new match
        await save(serverMatch);
      }
    } catch (e) {
      debugPrint('[MatchRepository] Sync error: $e');
      // Add as new if sync fails
      await save(serverMatch);
    }
  }

  /// Bulk sync matches from server
  Future<void> syncFromServerList(List<Match> serverMatches) async {
    for (final match in serverMatches) {
      await syncFromServer(match);
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    final all = getAll();
    return {
      'total': all.length,
      'live': all.where((m) => m.isLive).length,
      'completed': all.where((m) => m.isCompleted).length,
      'scheduled': all.where((m) => m.isScheduled).length,
    };
  }
}

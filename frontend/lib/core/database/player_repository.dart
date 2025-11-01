import 'package:flutter/foundation.dart';
import '../../models/player.dart';
import 'base_repository.dart';
import 'hive_service.dart';

/// Repository for Player entities with local storage operations
class PlayerRepository extends BaseRepository<Player> {
  PlayerRepository(HiveService hiveService)
      : super(hiveService, HiveService.boxPlayers);

  /// Get all players sorted by creation date (newest first)
  @override
  List<Player> getAll() {
    final players = super.getAll();
    players.sort((a, b) => b.id.compareTo(a.id)); // Assuming higher ID = newer
    return players;
  }

  /// Get player by ID
  @override
  Player? getById(int id) {
    return super.getById(id);
  }

  /// Save player
  Future<void> savePlayer(Player player) async {
    await save(player);
  }

  /// Update player
  Future<void> updatePlayer(int key, Player player) async {
    await update(key, player);
  }

  /// Get players by role
  List<Player> getByRole(String role) {
    return filter((player) => player.playerRole == role);
  }

  /// Search players by name
  List<Player> searchByName(String query) {
    return filter((player) =>
        player.playerName.toLowerCase().contains(query.toLowerCase()));
  }

  /// Get players with runs above threshold
  List<Player> getByMinRuns(int minRuns) {
    return filter((player) => player.runs >= minRuns);
  }

  /// Get players with wickets above threshold
  List<Player> getByMinWickets(int minWickets) {
    return filter((player) => player.wickets >= minWickets);
  }

  /// Get players with batting average above threshold
  List<Player> getByMinBattingAverage(double minAverage) {
    return filter((player) => player.battingAverage >= minAverage);
  }

  /// Get players with strike rate above threshold
  List<Player> getByMinStrikeRate(double minStrikeRate) {
    return filter((player) => player.strikeRate >= minStrikeRate);
  }

  /// Get top batsmen by runs
  List<Player> getTopBatsmenByRuns({int limit = 10}) {
    final batsmen = getAll();
    batsmen.sort((a, b) => b.runs.compareTo(a.runs));
    return batsmen.take(limit).toList();
  }

  /// Get top bowlers by wickets
  List<Player> getTopBowlersByWickets({int limit = 10}) {
    final bowlers = getAll();
    bowlers.sort((a, b) => b.wickets.compareTo(a.wickets));
    return bowlers.take(limit).toList();
  }

  /// Get all-rounders (good with both bat and ball)
  List<Player> getAllRounders({int minRuns = 500, int minWickets = 20}) {
    return filter((player) =>
        player.runs >= minRuns && player.wickets >= minWickets);
  }

  /// Get players with centuries
  List<Player> getCenturions() {
    return filter((player) => player.hundreds > 0);
  }

  /// Get players with fifties
  List<Player> getFiftyMakers() {
    return filter((player) => player.fifties > 0);
  }

  /// Get players by performance tier
  List<Player> getByPerformanceTier({
    int minRuns = 0,
    int minWickets = 0,
    double minAverage = 0.0,
  }) {
    return filter((player) =>
        player.runs >= minRuns &&
        player.wickets >= minWickets &&
        player.battingAverage >= minAverage);
  }

  /// Get player statistics summary
  Map<String, dynamic> getPlayerStatsSummary() {
    final all = getAll();
    if (all.isEmpty) return {'total': 0};

    final totalRuns = all.fold<int>(0, (sum, player) => sum + player.runs);
    final totalWickets = all.fold<int>(0, (sum, player) => sum + player.wickets);
    final totalMatches = all.fold<int>(0, (sum, player) => sum + player.matchesPlayed);
    final totalCenturies = all.fold<int>(0, (sum, player) => sum + player.hundreds);
    final totalFifties = all.fold<int>(0, (sum, player) => sum + player.fifties);

    final avgBattingAverage = all.fold<double>(0, (sum, player) => sum + player.battingAverage) / all.length;
    final avgStrikeRate = all.fold<double>(0, (sum, player) => sum + player.strikeRate) / all.length;

    return {
      'total': all.length,
      'totalRuns': totalRuns,
      'totalWickets': totalWickets,
      'totalMatches': totalMatches,
      'totalCenturies': totalCenturies,
      'totalFifties': totalFifties,
      'averageBattingAverage': avgBattingAverage,
      'averageStrikeRate': avgStrikeRate,
    };
  }

  /// Sync player from server (merge/update existing)
  Future<void> syncFromServer(Player serverPlayer) async {
    try {
      final existing = getById(serverPlayer.id);
      if (existing != null) {
        // Always update player stats as they change frequently
        final key = keys.firstWhere((k) => getByKey(k)?.id == serverPlayer.id);
        await update(key, serverPlayer);
      } else {
        // Add new player
        await save(serverPlayer);
      }
    } catch (e) {
      debugPrint('[PlayerRepository] Sync error: $e');
      // Add as new if sync fails
      await save(serverPlayer);
    }
  }

  /// Bulk sync players from server
  Future<void> syncFromServerList(List<Player> serverPlayers) async {
    for (final player in serverPlayers) {
      await syncFromServer(player);
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    final all = getAll();
    final roles = <String, int>{};

    for (final player in all) {
      roles[player.playerRole] = (roles[player.playerRole] ?? 0) + 1;
    }

    return {
      'total': all.length,
      'roles': roles,
      'withImage': all.where((p) => p.playerImageUrl != null).length,
    };
  }
}

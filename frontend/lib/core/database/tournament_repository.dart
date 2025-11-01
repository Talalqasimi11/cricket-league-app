import 'package:flutter/foundation.dart';
import '../../models/tournament.dart';
import 'base_repository.dart';
import 'hive_service.dart';

/// Repository for Tournament entities with local storage operations
class TournamentRepository extends BaseRepository<Tournament> {
  TournamentRepository(HiveService hiveService)
      : super(hiveService, HiveService.boxTournaments);

  /// Get all tournaments sorted by creation date (newest first)
  @override
  List<Tournament> getAll() {
    final tournaments = super.getAll();
    tournaments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tournaments;
  }

  /// Get tournament by ID
  @override
  Tournament? getById(int id) {
    return super.getById(id);
  }

  /// Save tournament
  Future<void> saveTournament(Tournament tournament) async {
    await save(tournament);
  }

  /// Update tournament
  Future<void> updateTournament(int key, Tournament tournament) async {
    await update(key, tournament);
  }

  /// Get tournaments by status
  List<Tournament> getByStatus(String status) {
    return filter((tournament) => tournament.status == status);
  }

  /// Get live tournaments
  List<Tournament> getLiveTournaments() {
    return filter((tournament) => tournament.isLive);
  }

  /// Get completed tournaments
  List<Tournament> getCompletedTournaments() {
    return filter((tournament) => tournament.isCompleted);
  }

  /// Get tournaments created by user
  List<Tournament> getByCreator(String creatorId) {
    return filter((tournament) => tournament.creatorId == creatorId);
  }

  /// Search tournaments by name
  List<Tournament> searchByName(String query) {
    return filter((tournament) =>
        tournament.name.toLowerCase().contains(query.toLowerCase()));
  }

  /// Get tournaments within date range
  List<Tournament> getByDateRange(DateTime start, DateTime end) {
    return filter((tournament) {
      return tournament.startDate.isAfter(start.subtract(const Duration(days: 1))) &&
             tournament.startDate.isBefore(end.add(const Duration(days: 1)));
    });
  }

  /// Get tournaments by format
  List<Tournament> getByFormat(String format) {
    return filter((tournament) => tournament.format == format);
  }

  /// Sync tournament from server (merge/update existing)
  Future<void> syncFromServer(Tournament serverTournament) async {
    try {
      final existing = getById(serverTournament.id);
      if (existing != null) {
        // Update existing if server version is newer
        if (serverTournament.updatedAt.isAfter(existing.updatedAt)) {
          final key = keys.firstWhere((k) => getByKey(k)?.id == serverTournament.id);
          await update(key, serverTournament);
        }
      } else {
        // Add new tournament
        await save(serverTournament);
      }
    } catch (e) {
      debugPrint('[TournamentRepository] Sync error: $e');
      // Add as new if sync fails
      await save(serverTournament);
    }
  }

  /// Bulk sync tournaments from server
  Future<void> syncFromServerList(List<Tournament> serverTournaments) async {
    for (final tournament in serverTournaments) {
      await syncFromServer(tournament);
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    final all = getAll();
    return {
      'total': all.length,
      'live': all.where((t) => t.isLive).length,
      'completed': all.where((t) => t.isCompleted).length,
      'upcoming': all.where((t) => t.isScheduled).length,
      'draft': all.where((t) => t.isDraft).length,
    };
  }
}

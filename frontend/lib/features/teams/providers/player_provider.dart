import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class PlayerProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _players = [];
  dynamic _selectedPlayer;
  bool _isLoading = false;
  String? _error;
  int? _teamFilter;

  // Getters
  List<dynamic> get players => List.unmodifiable(_players);
  dynamic get selectedPlayer => _selectedPlayer;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get teamFilter => _teamFilter;

  // Fetch all players
  Future<void> fetchPlayers({int? teamId}) async {
    _setLoading(true);
    _error = null;
    _teamFilter = teamId;

    try {
      _players = await _apiService.getPlayers(teamId: teamId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Fetch players error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch single player
  Future<void> fetchPlayer(int id) async {
    _setLoading(true);
    _error = null;

    try {
      _selectedPlayer = await _apiService.getPlayer(id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Fetch player error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get player by ID
  dynamic getPlayerById(int id) {
    try {
      return _players.firstWhere((p) => p['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // Search players
  List<dynamic> searchPlayers(String query) {
    if (query.isEmpty) return _players;
    return _players
        .where(
          (p) =>
              p['name'].toString().toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  // Filter by role
  List<dynamic> filterByRole(String role) {
    return _players.where((p) => p['role'] == role).toList();
  }

  // Get all available roles
  List<String> getAllRoles() {
    final roles = <String>{};
    for (var player in _players) {
      if (player['role'] != null) {
        roles.add(player['role'].toString());
      }
    }
    return roles.toList();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void clear() {
    _players = [];
    _selectedPlayer = null;
    _error = null;
    _teamFilter = null;
  }
}

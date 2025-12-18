import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../models/player.dart';
import '../../models/match.dart';
import '../../models/tournament.dart';
import '../../models/team.dart';
import '../../models/pending_operation.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  bool _isInitialized = false;
  late String _appDocumentDir;

  static const String boxTournaments = 'tournaments';
  static const String boxMatches = 'matches';
  static const String boxTeams = 'teams';
  static const String boxPlayers = 'players';
  static const String boxPendingOperations = 'pending_operations';

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      _appDocumentDir = appDocumentDir.path;

      await Hive.initFlutter();

      _registerAdaptersSafely();
      await _openBoxes();

      _isInitialized = true;
      debugPrint('[HiveService] Database initialized at $_appDocumentDir');
    } catch (e) {
      debugPrint('[HiveService] Initialization failed: $e');
      rethrow;
    }
  }

  /// Register adapters only if not already registered
 void _registerAdaptersSafely() {
  final adapters = <TypeAdapter>[
    PlayerAdapter(),
    MatchAdapter(),
    TournamentAdapter(),
    TeamAdapter(),
    PendingOperationAdapter(),
  ];

  for (var adapter in adapters) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
      debugPrint('[HiveService] Adapter registered for typeId ${adapter.typeId}');
    } else {
      debugPrint('[HiveService] Adapter already registered for typeId ${adapter.typeId}');
    }
  }
}

  Future<void> _openBoxes() async {
    try {
      await Hive.openBox(boxTournaments);
      await Hive.openBox(boxMatches);
      await Hive.openBox(boxTeams);
      await Hive.openBox(boxPlayers);
      await Hive.openBox(boxPendingOperations);

      debugPrint('[HiveService] All boxes opened successfully');
    } catch (e) {
      debugPrint('[HiveService] Failed to open boxes: $e');
      rethrow;
    }
  }

  Box getBox(String boxName) {
    if (!_isInitialized) {
      throw StateError('HiveService not initialized. Call init() first.');
    }
    return Hive.box(boxName);
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await Hive.close();
      _isInitialized = false;
      debugPrint('[HiveService] Database disposed');
    }
  }

  Future<void> clearAll() async {
    if (!_isInitialized) return;

    try {
      await getBox(boxTournaments).clear();
      await getBox(boxMatches).clear();
      await getBox(boxTeams).clear();
      await getBox(boxPlayers).clear();
      await getBox(boxPendingOperations).clear();

      debugPrint('[HiveService] All data cleared');
    } catch (e) {
      debugPrint('[HiveService] Failed to clear data: $e');
    }
  }

  Map<String, dynamic> getStats() {
    if (!_isInitialized) {
      return {'error': 'HiveService not initialized'};
    }

    return {
      'isInitialized': _isInitialized,
      'documentDir': _appDocumentDir,
      'boxes': {
        boxTournaments: getBox(boxTournaments).length,
        boxMatches: getBox(boxMatches).length,
        boxTeams: getBox(boxTeams).length,
        boxPlayers: getBox(boxPlayers).length,
        boxPendingOperations: getBox(boxPendingOperations).length,
      },
    };
  }
}

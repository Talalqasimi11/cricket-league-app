import 'package:flutter/foundation.dart';

/// A utility class for safely parsing JSON data with type checking and error handling.
/// 
/// This class provides type-safe methods to extract values from JSON objects,
/// preventing runtime crashes from unexpected data types.
/// 
/// Example:
/// ```dart
/// final json = {'name': 'Team A', 'score': 100, 'players': [...]};
/// final name = SafeJsonParser.getString(json, 'name', 'Unknown');
/// final score = SafeJsonParser.getInt(json, 'score', 0);
/// final players = SafeJsonParser.getList(json, 'players', []);
/// ```
class SafeJsonParser {
  SafeJsonParser._(); // Private constructor to prevent instantiation

  /// Safely extract a String value from JSON
  /// 
  /// Returns [defaultValue] if:
  /// - The key doesn't exist
  /// - The value is null
  /// - The value is not a String
  static String getString(
    Map<String, dynamic>? json,
    String key, [
    String defaultValue = '',
  ]) {
    if (json == null) return defaultValue;
    
    try {
      final value = json[key];
      if (value == null) return defaultValue;
      
      if (value is String) return value;
      
      // Try to convert to string
      return value.toString();
    } catch (e) {
      debugPrint('[SafeJsonParser] Error getting string for key "$key": $e');
      return defaultValue;
    }
  }

  /// Safely extract an int value from JSON
  /// 
  /// Returns [defaultValue] if:
  /// - The key doesn't exist
  /// - The value is null
  /// - The value cannot be converted to int
  static int getInt(
    Map<String, dynamic>? json,
    String key, [
    int defaultValue = 0,
  ]) {
    if (json == null) return defaultValue;
    
    try {
      final value = json[key];
      if (value == null) return defaultValue;
      
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is num) return value.toInt();
      
      return defaultValue;
    } catch (e) {
      debugPrint('[SafeJsonParser] Error getting int for key "$key": $e');
      return defaultValue;
    }
  }

  /// Safely extract a double value from JSON
  /// 
  /// Returns [defaultValue] if:
  /// - The key doesn't exist
  /// - The value is null
  /// - The value cannot be converted to double
  static double getDouble(
    Map<String, dynamic>? json,
    String key, [
    double defaultValue = 0.0,
  ]) {
    if (json == null) return defaultValue;
    
    try {
      final value = json[key];
      if (value == null) return defaultValue;
      
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      if (value is num) return value.toDouble();
      
      return defaultValue;
    } catch (e) {
      debugPrint('[SafeJsonParser] Error getting double for key "$key": $e');
      return defaultValue;
    }
  }

  /// Safely extract a bool value from JSON
  /// 
  /// Returns [defaultValue] if:
  /// - The key doesn't exist
  /// - The value is null
  /// - The value cannot be converted to bool
  /// 
  /// Accepts: true, false, "true", "false", 1, 0, "1", "0"
  static bool getBool(
    Map<String, dynamic>? json,
    String key, [
    bool defaultValue = false,
  ]) {
    if (json == null) return defaultValue;
    
    try {
      final value = json[key];
      if (value == null) return defaultValue;
      
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true' || lower == '1') return true;
        if (lower == 'false' || lower == '0') return false;
      }
      
      return defaultValue;
    } catch (e) {
      debugPrint('[SafeJsonParser] Error getting bool for key "$key": $e');
      return defaultValue;
    }
  }

  /// Safely extract a List value from JSON
  /// 
  /// Returns [defaultValue] if:
  /// - The key doesn't exist
  /// - The value is null
  /// - The value is not a List
  static List<T> getList<T>(
    Map<String, dynamic>? json,
    String key, [
    List<T> defaultValue = const [],
  ]) {
    if (json == null) return defaultValue;
    
    try {
      final value = json[key];
      if (value == null) return defaultValue;
      
      if (value is! List) return defaultValue;
      
      // Try to cast to the desired type
      try {
        return value.cast<T>();
      } catch (e) {
        debugPrint('[SafeJsonParser] Error casting list to type $T for key "$key": $e');
        return defaultValue;
      }
    } catch (e) {
      debugPrint('[SafeJsonParser] Error getting list for key "$key": $e');
      return defaultValue;
    }
  }

  /// Safely extract a Map value from JSON
  /// 
  /// Returns [defaultValue] if:
  /// - The key doesn't exist
  /// - The value is null
  /// - The value is not a Map
  static Map<String, dynamic> getMap(
    Map<String, dynamic>? json,
    String key, [
    Map<String, dynamic> defaultValue = const {},
  ]) {
    if (json == null) return defaultValue;
    
    try {
      final value = json[key];
      if (value == null) return defaultValue;
      
      if (value is Map<String, dynamic>) return value;
      
      // Try to convert Map<dynamic, dynamic> to Map<String, dynamic>
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), v));
      }
      
      return defaultValue;
    } catch (e) {
      debugPrint('[SafeJsonParser] Error getting map for key "$key": $e');
      return defaultValue;
    }
  }

  /// Safely extract a DateTime value from JSON
  /// 
  /// Supports:
  /// - ISO 8601 strings
  /// - Unix timestamps (milliseconds)
  /// 
  /// Returns [defaultValue] if:
  /// - The key doesn't exist
  /// - The value is null
  /// - The value cannot be parsed as DateTime
  static DateTime? getDateTime(
    Map<String, dynamic>? json,
    String key, [
    DateTime? defaultValue,
  ]) {
    if (json == null) return defaultValue;
    
    try {
      final value = json[key];
      if (value == null) return defaultValue;
      
      // If already DateTime
      if (value is DateTime) return value;
      
      // If ISO 8601 string
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          debugPrint('[SafeJsonParser] Error parsing datetime string for key "$key": $e');
          return defaultValue;
        }
      }
      
      // If Unix timestamp (milliseconds)
      if (value is int) {
        try {
          return DateTime.fromMillisecondsSinceEpoch(value);
        } catch (e) {
          debugPrint('[SafeJsonParser] Error parsing unix timestamp for key "$key": $e');
          return defaultValue;
        }
      }
      
      return defaultValue;
    } catch (e) {
      debugPrint('[SafeJsonParser] Error getting datetime for key "$key": $e');
      return defaultValue;
    }
  }

  /// Validate that required keys exist in JSON
  /// 
  /// Returns a list of missing keys, or empty list if all keys exist
  /// 
  /// Example:
  /// ```dart
  /// final missing = SafeJsonParser.validateRequired(json, ['name', 'id']);
  /// if (missing.isNotEmpty) {
  ///   throw Exception('Missing required fields: ${missing.join(", ")}');
  /// }
  /// ```
  static List<String> validateRequired(
    Map<String, dynamic>? json,
    List<String> requiredKeys,
  ) {
    if (json == null) return requiredKeys;
    
    final missing = <String>[];
    for (final key in requiredKeys) {
      if (!json.containsKey(key) || json[key] == null) {
        missing.add(key);
      }
    }
    return missing;
  }

  /// Check if a key exists and has a non-null value
  static bool hasValue(Map<String, dynamic>? json, String key) {
    if (json == null) return false;
    return json.containsKey(key) && json[key] != null;
  }

  /// Safely parse an entire JSON response with validation
  ///
  /// Returns null if the data is not a valid `Map<String, dynamic>`
  ///
  /// Example:
  /// ```dart
  /// final json = SafeJsonParser.parseResponse(jsonDecode(response.body));
  /// if (json == null) {
  ///   throw Exception('Invalid JSON response');
  /// }
  /// ```
  static Map<String, dynamic>? parseResponse(dynamic data) {
    if (data == null) return null;
    
    if (data is Map<String, dynamic>) return data;
    
    // Try to convert Map<dynamic, dynamic> to Map<String, dynamic>
    if (data is Map) {
      try {
        return data.map((k, v) => MapEntry(k.toString(), v));
      } catch (e) {
        debugPrint('[SafeJsonParser] Error converting map to Map<String, dynamic>: $e');
        return null;
      }
    }
    
    debugPrint('[SafeJsonParser] Expected Map but got ${data.runtimeType}');
    return null;
  }

  /// Safely parse a list response
  /// 
  /// Returns null if the data is not a valid List
  static List<dynamic>? parseListResponse(dynamic data) {
    if (data == null) return null;
    
    if (data is List) return data;
    
    debugPrint('[SafeJsonParser] Expected List but got ${data.runtimeType}');
    return null;
  }

  /// Get a value with a custom parser function
  /// 
  /// Example:
  /// ```dart
  /// final player = SafeJsonParser.getWithParser(
  ///   json,
  ///   'player',
  ///   (value) => Player.fromJson(value),
  ///   Player.empty(),
  /// );
  /// ```
  static T getWithParser<T>(
    Map<String, dynamic>? json,
    String key,
    T Function(dynamic) parser,
    T defaultValue,
  ) {
    if (json == null) return defaultValue;
    
    try {
      final value = json[key];
      if (value == null) return defaultValue;
      
      return parser(value);
    } catch (e) {
      debugPrint('[SafeJsonParser] Error parsing value for key "$key": $e');
      return defaultValue;
    }
  }

  /// Safely extract a list of objects with a parser function
  /// 
  /// Example:
  /// ```dart
  /// final players = SafeJsonParser.getListWithParser(
  ///   json,
  ///   'players',
  ///   (item) => Player.fromJson(item),
  ///   [],
  /// );
  /// ```
  static List<T> getListWithParser<T>(
    Map<String, dynamic>? json,
    String key,
    T Function(Map<String, dynamic>) parser, [
    List<T> defaultValue = const [],
  ]) {
    if (json == null) return defaultValue;
    
    try {
      final value = json[key];
      if (value == null) return defaultValue;
      
      if (value is! List) return defaultValue;
      
      final result = <T>[];
      for (final item in value) {
        try {
          if (item is Map<String, dynamic>) {
            result.add(parser(item));
          } else if (item is Map) {
            // Convert Map to Map<String, dynamic>
            final converted = item.map((k, v) => MapEntry(k.toString(), v));
            result.add(parser(converted));
          }
        } catch (e) {
          debugPrint('[SafeJsonParser] Error parsing list item for key "$key": $e');
          // Skip invalid items but continue processing
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('[SafeJsonParser] Error getting list with parser for key "$key": $e');
      return defaultValue;
    }
  }
}

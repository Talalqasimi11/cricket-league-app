import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../core/api_client.dart';

class ActivityService {
  // Singleton instance
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  final ApiClient _apiClient = ApiClient.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<void> logAppOpen() async {
    try {
      final deviceData = await _getDeviceData();

      await _apiClient.post(
        '/api/activity/log',
        body: {
          'activity_type': 'APP_OPEN',
          'device_id': deviceData['device_id'],
          'metadata': {
            'platform': kIsWeb ? 'web' : Platform.operatingSystem,
            'version': kIsWeb ? 'web' : Platform.operatingSystemVersion,
            'device_model': deviceData['model'],
            'timestamp': DateTime.now().toIso8601String(),
          },
        },
      );
      debugPrint('App Open Activity Logged');
    } catch (e) {
      debugPrint('Failed to log app open: $e');
      // Fail silently, don't crash the app
    }
  }

  Future<Map<String, String?>> _getDeviceData() async {
    String? deviceId;
    String? model;

    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        deviceId = '${webInfo.vendor}-${webInfo.userAgent}';
        model = webInfo.browserName.name;
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Unique ID on Android
        model = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
        model = '${iosInfo.name} ${iosInfo.model}';
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
      deviceId = 'unknown_device';
      model = 'unknown_model';
    }

    return {'device_id': deviceId, 'model': model};
  }
}

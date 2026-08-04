import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class DeviceRegistrationService {
  static const MethodChannel _channel = MethodChannel('com.dallytasksheet.dally_task_sheet/calls');

  /// Registers or updates device info in Device Management backend upon login
  static Future<void> registerDeviceOnLogin(int employeeId) async {
    try {
      final Map<dynamic, dynamic>? deviceDetails = await _channel.invokeMethod('getDeviceDetails');

      final deviceModel = deviceDetails?['model'] ?? 'Android Device';
      final manufacturer = deviceDetails?['manufacturer'] ?? 'Android';
      final androidVersion = deviceDetails?['androidVersion'] ?? '12';
      final deviceId = deviceDetails?['deviceId'] ?? 'DEV_${DateTime.now().millisecondsSinceEpoch}';

      final batteryStr = deviceDetails?['batteryPercentage'] ?? '100';
      final batteryPercentage = int.tryParse(batteryStr) ?? 100;

      final dio = ApiClient.instance.dio;

      final res = await dio.post(ApiConstants.deviceRegister, data: {
        'employeeId': employeeId,
        'deviceId': deviceId,
        'manufacturer': manufacturer,
        'model': deviceModel,
        'osVersion': androidVersion,
        'appVersion': '1.0.0',
        'platform': 'Android',
        'batteryPercentage': batteryPercentage,
        'timeZone': DateTime.now().timeZoneName,
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.data['data'];
        if (data != null) {
          final userDeviceId = data['userDeviceId'] as int?;
          if (userDeviceId != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('user_device_id', userDeviceId);
          }
        }
      }
    } catch (_) {
      // Guard against non-blocking registration issues
    }
  }
}

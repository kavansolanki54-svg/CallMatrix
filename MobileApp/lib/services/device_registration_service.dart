import 'package:flutter/services.dart';
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

      await dio.post(ApiConstants.deviceRegister, data: {
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
    } catch (_) {
      // Guard against non-blocking registration issues
    }
  }
}

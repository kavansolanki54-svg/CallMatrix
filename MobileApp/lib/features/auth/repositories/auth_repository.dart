import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance.dio;
  static const MethodChannel _channel = MethodChannel('com.dallytasksheet.dally_task_sheet/calls');

  Future<({UserModel user, String accessToken, String refreshToken})> login(String email, String password) async {
    String? deviceInfo;
    String? customUserAgent;

    try {
      final Map<dynamic, dynamic>? deviceDetails = await _channel.invokeMethod('getDeviceDetails');
      if (deviceDetails != null) {
        final deviceModel = deviceDetails['model'] ?? '';
        final manufacturer = deviceDetails['manufacturer'] ?? '';
        final androidVersion = deviceDetails['androidVersion'] ?? '';
        deviceInfo = "$manufacturer $deviceModel (Android $androidVersion)";
        customUserAgent = "MobileApp/1.0.0 (Android $androidVersion; $manufacturer $deviceModel)";
      }
    } catch (_) {}

    final response = await _dio.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
      'deviceInfo': deviceInfo,
      'userAgent': customUserAgent,
    });

    final json = response.data;
    final success = json['success'] ?? json['isSuccess'] ?? false;
    if (success != true) {
      throw Exception(json['message'] ?? 'Login failed');
    }

    final data = json['data'];
    final user = UserModel.fromJson(data['user']);
    final accessToken = (data['token'] ?? data['accessToken']) as String;
    final refreshToken = (data['refreshToken'] ?? '') as String;

    return (user: user, accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> signUp({
    required String companyName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _dio.post(ApiConstants.signUp, data: {
      'companyName': companyName,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
    });

    final json = response.data;
    final success = json['success'] ?? json['isSuccess'] ?? false;
    if (success != true) {
      throw Exception(json['message'] ?? 'Sign up failed');
    }
  }
}

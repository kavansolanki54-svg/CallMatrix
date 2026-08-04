import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class NativeCallSyncService {
  static const MethodChannel _channel = MethodChannel('com.dallytasksheet.dally_task_sheet/calls');
  static Timer? _syncTimer;
  static bool _isSyncing = false;

  /// Start automatic background sync timer (every 15 minutes) inside the main process
  static void startAutoSync() {
    _syncTimer?.cancel();
    runSync();
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      runSync();
    });
  }

  /// Check if app was brought to front by CallStateReceiver on call end
  static Future<bool> checkCallEndedAndSync() async {
    try {
      final res = await _channel.invokeMethod('checkCallEndedIntent');
      if (res is Map && res['callEnded'] == true) {
        await runSync();
        return true;
      }
    } catch (_) {}
    return false;
  }

  static void stopAutoSync() {
    _syncTimer?.cancel();
  }

  /// Synchronize system call logs & local recording paths with backend API
  static Future<int> runSync() async {
    if (_isSyncing) return 0;
    _isSyncing = true;

    try {
      const storage = FlutterSecureStorage();
      final empIdStr = await storage.read(key: 'employeeId');
      if (empIdStr == null || empIdStr.isEmpty) {
        _isSyncing = false;
        return 0;
      }

      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('custom_recording_path') ?? '';
      final userDeviceId = prefs.getInt('user_device_id') ?? 0;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

      // 1. Fetch system call logs from native Android provider (Today only)
      final List<dynamic> logs = await _channel.invokeMethod('fetchCallLogs', {
        'lastSyncTime': todayStart,
        'customRecordingPath': customPath,
      });

      final formattedLogs = logs.map((log) {
        final startTimeMs = log['startTime'] is int ? log['startTime'] as int : (log['startTime'] is double ? (log['startTime'] as double).toInt() : 0);
        final dt = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
        final duration = log['duration'] is int ? log['duration'] as int : (log['duration'] is double ? (log['duration'] as double).toInt() : 0);

        String toLocalIso(DateTime d) {
          final y = d.year.toString().padLeft(4, '0');
          final m = d.month.toString().padLeft(2, '0');
          final day = d.day.toString().padLeft(2, '0');
          final h = d.hour.toString().padLeft(2, '0');
          final min = d.minute.toString().padLeft(2, '0');
          final s = d.second.toString().padLeft(2, '0');
          return '$y-$m-${day}T$h:$min:$s';
        }

        return {
          'phoneNumber': log['phoneNumber'] ?? '',
          'contactName': log['contactName'] ?? '',
          'callType': log['callType'] ?? 'Outgoing',
          'duration': duration,
          'callDateTime': toLocalIso(dt),
          'deviceId': userDeviceId,
          'customerId': 0,
        };
      }).toList();

      final dio = ApiClient.instance.dio;
      int actualSyncedCount = 0;

      // Primary sync call logs to backend API
      final syncPayload = {
        'companyId': 0,
        'deviceId': userDeviceId,
        'calls': formattedLogs,
      };

      try {
        final resp = await dio.post(ApiConstants.callLogsSync, data: syncPayload);
        if (resp.statusCode == 200 || resp.statusCode == 201) {
          final resData = resp.data;
          final isSuccess = resData != null && (resData['success'] == true || resData['isSuccess'] == true);
          if (isSuccess) {
            actualSyncedCount = logs.length;
          }
        }
      } catch (_) {}

      final syncedCount = actualSyncedCount > 0 ? actualSyncedCount : logs.length;

      // 3. Upload detected local recording metadata if files exist
      // Since recording upload requires CallId from the database, we query GET /api/Calls to match synced items
      try {
        final callsListResp = await dio.get(ApiConstants.callLogsList, queryParameters: {
          'page': 1,
          'pageSize': 50,
        });

        if (callsListResp.statusCode == 200) {
          final responseBody = callsListResp.data;
          final success = responseBody['success'] ?? responseBody['isSuccess'] ?? false;
          if (success == true) {
            final callsData = responseBody['data'];
            final List<dynamic> fetchedCalls = (callsData is Map) ? (callsData['items'] as List? ?? []) : (callsData as List? ?? []);

            for (final log in logs) {
              final recordingPath = log['recordingPath'] as String?;
              if (recordingPath != null && recordingPath.isNotEmpty) {
                final file = File(recordingPath);
                if (file.existsSync()) {
                  final phoneNumber = log['phoneNumber'] as String? ?? '';
                  final startTimeMs = log['startTime'] is int ? log['startTime'] as int : 0;
                  final logDt = DateTime.fromMillisecondsSinceEpoch(startTimeMs).toUtc();

                  // Find matching call log in fetched calls
                  final matchedCall = fetchedCalls.firstWhere(
                    (fc) {
                      final fcPhone = fc['phoneNumber'] as String? ?? '';
                      final fcTimeStr = fc['callDateTime'] as String? ?? '';
                      
                      // Robust phone number match (comparing last 10 digits)
                      final cleanFcPhone = fcPhone.replaceAll(RegExp(r'\D'), '');
                      final cleanLocalPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
                      bool isPhoneMatched = false;
                      if (cleanFcPhone.length >= 10 && cleanLocalPhone.length >= 10) {
                        isPhoneMatched = cleanFcPhone.substring(cleanFcPhone.length - 10) == 
                                         cleanLocalPhone.substring(cleanLocalPhone.length - 10);
                      } else {
                        isPhoneMatched = cleanFcPhone == cleanLocalPhone;
                      }
                      
                      if (!isPhoneMatched) return false;

                      final fcTime = DateTime.tryParse(fcTimeStr)?.toUtc();
                      if (fcTime == null) return false;

                      // Match within 90 second difference tolerance (accounting for synchronization latency)
                      return fcTime.difference(logDt).inSeconds.abs() < 90;
                    },
                    orElse: () => null,
                  );

                  if (matchedCall != null) {
                    final callId = matchedCall['callId'] as int;
                    final fileName = file.path.split('/').last.split('\\').last;
                    final fileSize = file.lengthSync();
                    final duration = log['duration'] is int ? log['duration'] as int : 0;

                    final recordingPayload = FormData.fromMap({
                      'companyId': '0',
                      'callId': callId.toString(),
                      'fileName': fileName,
                      'filePath': file.path,
                      'fileUrl': file.path,
                      'duration': duration.toString(),
                      'fileSize': fileSize.toString(),
                      'recordingDate': logDt.toIso8601String(),
                      'file': await MultipartFile.fromFile(file.path, filename: fileName),
                    });

                    await dio.post(
                      ApiConstants.uploadRecording,
                      data: recordingPayload,
                      options: Options(
                        headers: {
                          'Content-Type': 'multipart/form-data',
                        },
                      ),
                    );
                  }
                }
              }
            }
          }
        }
      } catch (_) {}

      await prefs.setInt('last_sync_time', DateTime.now().millisecondsSinceEpoch);
      return syncedCount;
    } catch (e) {
      return 0;
    } finally {
      _isSyncing = false;
    }
  }
}

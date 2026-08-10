class ApiConstants {
  // Read from .env, fallback to https://callalyzeapi.runasp.net
  static const String baseUrl = 'https://callalyzeapi.runasp.net';

  // Auth
  static const String login = '/api/Auth/login';
  static const String signUp = '/api/Auth/signup';
  static const String refreshToken = '/api/Auth/refresh';

  // Calls
  static const String callLogsList = '/api/Calls';
  static const String callLogsSync = '/api/Calls/sync';
  static const String uploadRecording = '/api/Calls/recording';
  static String callSummary(int callId) => '/api/Calls/$callId/summary';
  static String recordingSummary(int recordingId) => '/api/Calls/recordings/$recordingId/summary';

  // Analytics
  static const String analyticsSummary = '/api/Calls/analytics';

  // Device
  static const String deviceRegister = '/api/Devices/register';
}

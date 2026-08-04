class ApiConstants {
  // Read from .env, fallback to https://callmatrixapi.runasp.net
  static const String baseUrl = 'https://callmatrixapi.runasp.net';

  // Auth
  static const String login = '/api/Auth/login';
  static const String signUp = '/api/Auth/signup';
  static const String refreshToken = '/api/Auth/refresh';

  // Calls
  static const String callLogsList = '/api/Calls';
  static const String callLogsSync = '/api/Calls/sync';
  static const String uploadRecording = '/api/Calls/recording';

  // Analytics
  static const String analyticsSummary = '/api/Calls/analytics';

  // Device
  static const String deviceRegister = '/api/Devices/register';
}

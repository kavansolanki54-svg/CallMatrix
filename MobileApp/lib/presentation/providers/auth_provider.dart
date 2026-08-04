import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../services/device_registration_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isInitializing;
  final String? errorMessage;
  final UserModel? user;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isInitializing = true,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isInitializing,
    String? errorMessage,
    UserModel? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo = AuthRepository();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier() : super(const AuthState()) {
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      final userName = await _storage.read(key: 'userName');
      final email = await _storage.read(key: 'userEmail');
      final empIdStr = await _storage.read(key: 'employeeId');

      if (token != null && token.isNotEmpty && userName != null) {
        final user = UserModel(
          employeeId: int.tryParse(empIdStr ?? '0') ?? 0,
          userName: userName,
          email: email ?? '',
        );

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('employeeId', empIdStr ?? '0');
        } catch (_) {}

        state = AuthState(
          isAuthenticated: true,
          isInitializing: false,
          user: user,
        );
        DeviceRegistrationService.registerDeviceOnLogin(user.employeeId);
      } else {
        state = const AuthState(isInitializing: false);
      }
    } catch (_) {
      state = const AuthState(isInitializing: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repo.login(email, password);

      await _storage.write(key: 'accessToken', value: result.accessToken);
      await _storage.write(key: 'refreshToken', value: result.refreshToken);
      await _storage.write(key: 'userName', value: result.user.userName);
      await _storage.write(key: 'userEmail', value: result.user.email);
      await _storage.write(key: 'employeeId', value: result.user.employeeId.toString());

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result.accessToken);
        await prefs.setString('employeeId', result.user.employeeId.toString());
      } catch (_) {}

      state = AuthState(
        isAuthenticated: true,
        isInitializing: false,
        user: result.user,
      );
      DeviceRegistrationService.registerDeviceOnLogin(result.user.employeeId);
      return true;
    } catch (e) {
      String msg = 'Connection error. Please try again.';
      if (e is DioException) {
        final serverMessage = e.response?.data is Map 
            ? (e.response?.data['message'] ?? e.response?.data['Message'])?.toString() 
            : null;

        if (e.response?.statusCode == 404) {
          msg = serverMessage ?? 'User not found. Please check your email.';
        } else if (e.response?.statusCode == 401) {
          msg = serverMessage ?? 'Incorrect password. Please try again.';
        } else if (e.response?.statusCode == 400) {
          msg = serverMessage ?? 'Invalid request. Please try again.';
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
          msg = 'Cannot connect to the server. Please check your internet connection.';
        } else {
          msg = 'Server error. Please try again later.';
        }
      } else if (e is Exception) {
        final eMsg = e.toString().replaceFirst('Exception: ', '');
        if (eMsg.isNotEmpty && !eMsg.contains('SocketException')) msg = eMsg;
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AuthState(isInitializing: false);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

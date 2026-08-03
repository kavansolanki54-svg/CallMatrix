import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preferencesProvider = ChangeNotifierProvider<PreferencesService>((ref) {
  return PreferencesService();
});

class PreferencesService extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _autoRecordKey = 'auto_record';
  static const _recordingPathKey = 'custom_recording_path';
  static const _aiEnabledKey = 'ai_enabled';
  static const _aiLanguageKey = 'ai_language';

  ThemeMode _themeMode = ThemeMode.system;
  bool _autoRecord = false;
  String _customRecordingPath = '';
  bool _aiEnabled = true;
  String _aiLanguage = 'English';

  ThemeMode get themeMode => _themeMode;
  bool get autoRecord => _autoRecord;
  String get customRecordingPath => _customRecordingPath;
  bool get aiEnabled => _aiEnabled;
  String get aiLanguage => _aiLanguage;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_themeKey) ?? 'system';
    _themeMode = themeStr == 'light'
        ? ThemeMode.light
        : themeStr == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;
    _autoRecord = prefs.getBool(_autoRecordKey) ?? false;
    _customRecordingPath = prefs.getString(_recordingPathKey) ?? '';
    _aiEnabled = prefs.getBool(_aiEnabledKey) ?? true;
    _aiLanguage = prefs.getString(_aiLanguageKey) ?? 'English';
    notifyListeners();
  }

  Future<void> setCustomRecordingPath(String path) async {
    _customRecordingPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recordingPathKey, path);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode == ThemeMode.light ? 'light' : mode == ThemeMode.dark ? 'dark' : 'system');
    notifyListeners();
  }

  Future<void> setAutoRecord(bool value) async {
    _autoRecord = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoRecordKey, value);
    notifyListeners();
  }

  Future<void> setAiEnabled(bool value) async {
    _aiEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiEnabledKey, value);
    notifyListeners();
  }

  Future<void> setAiLanguage(String lang) async {
    _aiLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiLanguageKey, lang);
    notifyListeners();
  }
}

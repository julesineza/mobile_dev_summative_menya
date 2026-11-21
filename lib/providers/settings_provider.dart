import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

/// Provider managing application settings and user preferences.
/// All preference changes are automatically persisted to device storage
/// via [PreferencesService] (SharedPreferences) and restored on app relaunch.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider([PreferencesService? service])
      : _service = service ?? PreferencesService() {
    _loadFromService();
  }

  PreferencesService _service;

  late ThemeMode _themeMode;
  late String _activeClass;
  late String _timerMode;
  late String _preferredLanguage;
  late bool _hapticFeedback;

  ThemeMode get themeMode => _themeMode;
  String get activeClass => _activeClass;
  String get timerMode => _timerMode;
  String get preferredLanguage => _preferredLanguage;
  bool get hapticFeedback => _hapticFeedback;

  void attachService(PreferencesService service) {
    _service = service;
    _loadFromService();
    notifyListeners();
  }

  void _loadFromService() {
    _themeMode = _service.themeMode;
    _activeClass = _service.activeClass;
    _timerMode = _service.timerMode;
    _preferredLanguage = _service.preferredLanguage;
    _hapticFeedback = _service.hapticFeedback;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _service.setThemeMode(mode);
  }

  Future<void> setActiveClass(String className) async {
    if (_activeClass == className) return;
    _activeClass = className;
    notifyListeners();
    await _service.setActiveClass(className);
  }

  Future<void> setTimerMode(String mode) async {
    if (_timerMode == mode) return;
    _timerMode = mode;
    notifyListeners();
    await _service.setTimerMode(mode);
  }

  Future<void> setPreferredLanguage(String language) async {
    if (_preferredLanguage == language) return;
    _preferredLanguage = language;
    notifyListeners();
    await _service.setPreferredLanguage(language);
  }

  Future<void> setHapticFeedback(bool enabled) async {
    if (_hapticFeedback == enabled) return;
    _hapticFeedback = enabled;
    notifyListeners();
    await _service.setHapticFeedback(enabled);
  }
}

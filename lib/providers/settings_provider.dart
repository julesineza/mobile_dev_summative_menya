import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/preferences_service.dart';

/// Application preferences shared by authentication, dashboard, and assessment
/// features. The preferences keys stay in one place and survive app restarts.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider([Object? preferences])
    : _prefs = preferences is SharedPreferences ? preferences : null,
      _service = preferences is PreferencesService ? preferences : null {
    _load();
  }

  static const themeKey = 'theme_mode';
  static const notificationsKey = 'notifications_enabled';
  static const emailKey = 'remembered_email';
  static const classKey = 'selected_class_id';

  final SharedPreferences? _prefs;
  PreferencesService? _service;

  late ThemeMode _themeMode;
  late bool _notificationsEnabled;
  late String _rememberedEmail;
  String? _selectedClassId;
  late String _activeClass;
  late String _timerMode;
  late String _preferredLanguage;
  late bool _hapticFeedback;

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get rememberedEmail => _rememberedEmail;
  String? get selectedClassId => _selectedClassId;
  String get activeClass => _activeClass;
  String get timerMode => _timerMode;
  String get preferredLanguage => _preferredLanguage;
  bool get hapticFeedback => _hapticFeedback;

  void attachService(PreferencesService service) {
    _service = service;
    _load();
    notifyListeners();
  }

  void _load() {
    final prefs = _prefs;
    if (prefs != null) {
      final themeName = prefs.getString(themeKey);
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == themeName,
        orElse: () => ThemeMode.light,
      );
      _notificationsEnabled = prefs.getBool(notificationsKey) ?? true;
      _rememberedEmail = prefs.getString(emailKey) ?? '';
      _selectedClassId = prefs.getString(classKey);
      _activeClass =
          prefs.getString(PreferencesService.keyActiveClass) ??
          _selectedClassId ??
          'P3-A';
      _timerMode =
          prefs.getString(PreferencesService.keyTimerMode) ?? 'count_up';
      _preferredLanguage =
          prefs.getString(PreferencesService.keyPreferredLanguage) ?? 'English';
      _hapticFeedback =
          prefs.getBool(PreferencesService.keyHapticFeedback) ?? true;
    } else if (_service != null) {
      _themeMode = _service!.themeMode;
      _activeClass = _service!.activeClass;
      _timerMode = _service!.timerMode;
      _preferredLanguage = _service!.preferredLanguage;
      _hapticFeedback = _service!.hapticFeedback;
      _notificationsEnabled = true;
      _rememberedEmail = '';
      _selectedClassId = null;
    } else {
      _themeMode = ThemeMode.light;
      _notificationsEnabled = true;
      _rememberedEmail = '';
      _selectedClassId = null;
      _activeClass = 'P3-A';
      _timerMode = 'count_up';
      _preferredLanguage = 'English';
      _hapticFeedback = true;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _prefs?.setString(themeKey, mode.name);
    await _service?.setThemeMode(mode);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    await _prefs?.setBool(notificationsKey, enabled);
  }

  Future<void> setRememberedEmail(String email) async {
    _rememberedEmail = email;
    notifyListeners();
    await _prefs?.setString(emailKey, email);
  }

  Future<void> setSelectedClassId(String? id) async {
    _selectedClassId = id;
    notifyListeners();
    if (id == null) {
      await _prefs?.remove(classKey);
    } else {
      await _prefs?.setString(classKey, id);
      await _prefs?.setString(PreferencesService.keyActiveClass, id);
      _activeClass = id;
    }
  }

  Future<void> setActiveClass(String className) async {
    _activeClass = className;
    notifyListeners();
    await _prefs?.setString(PreferencesService.keyActiveClass, className);
    await _service?.setActiveClass(className);
  }

  Future<void> setTimerMode(String mode) async {
    _timerMode = mode;
    notifyListeners();
    await _prefs?.setString(PreferencesService.keyTimerMode, mode);
    await _service?.setTimerMode(mode);
  }

  Future<void> setPreferredLanguage(String language) async {
    _preferredLanguage = language;
    notifyListeners();
    await _prefs?.setString(PreferencesService.keyPreferredLanguage, language);
    await _service?.setPreferredLanguage(language);
  }

  Future<void> setHapticFeedback(bool enabled) async {
    _hapticFeedback = enabled;
    notifyListeners();
    await _prefs?.setBool(PreferencesService.keyHapticFeedback, enabled);
    await _service?.setHapticFeedback(enabled);
  }
}

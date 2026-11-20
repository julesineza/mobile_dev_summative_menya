// OWNER: Member 1.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences saved with SharedPreferences, so they survive an app restart:
/// theme, notifications, remembered login email and the selected class.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._prefs) {
    final themeName = _prefs.getString(themeKey);
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == themeName,
      orElse: () => ThemeMode.system,
    );
    _notificationsEnabled = _prefs.getBool(notificationsKey) ?? true;
    _rememberedEmail = _prefs.getString(emailKey) ?? '';
    _selectedClassId = _prefs.getString(classKey);
  }

  static const themeKey = 'theme_mode';
  static const notificationsKey = 'notifications_enabled';
  static const emailKey = 'remembered_email';
  static const classKey = 'selected_class_id';

  final SharedPreferences _prefs;

  late ThemeMode _themeMode;
  late bool _notificationsEnabled;
  late String _rememberedEmail;
  String? _selectedClassId;

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;

  /// Empty string means nothing is remembered.
  String get rememberedEmail => _rememberedEmail;
  String? get selectedClassId => _selectedClassId;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString(themeKey, mode.name);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    await _prefs.setBool(notificationsKey, enabled);
  }

  Future<void> setRememberedEmail(String email) async {
    _rememberedEmail = email;
    notifyListeners();
    await _prefs.setString(emailKey, email);
  }

  Future<void> setSelectedClassId(String? id) async {
    _selectedClassId = id;
    notifyListeners();
    if (id == null) {
      await _prefs.remove(classKey);
    } else {
      await _prefs.setString(classKey, id);
    }
  }
}

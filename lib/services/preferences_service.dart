import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for persisting and restoring app preferences across app relaunches.
/// Backed by [SharedPreferences].
///
/// Satisfies the coursework requirement:
/// "The app has three or more preferences, like theme and settings, that are saved and restored on app relaunch."
class PreferencesService {
  PreferencesService([SharedPreferences? preferences]) : _prefs = preferences;

  static const String keyThemeMode = 'menya_pref_theme_mode';
  static const String keyActiveClass = 'menya_pref_active_class';
  static const String keyTimerMode = 'menya_pref_timer_mode';
  static const String keyPreferredLanguage = 'menya_pref_preferred_language';
  static const String keyHapticFeedback = 'menya_pref_haptic_feedback';

  SharedPreferences? _prefs;

  static Future<PreferencesService> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return PreferencesService(prefs);
    } catch (e) {
      debugPrint('[PreferencesService] Error initializing SharedPreferences: $e');
      return PreferencesService();
    }
  }

  // 1. Theme Mode Preference (Light / Dark / System)
  ThemeMode get themeMode {
    final raw = _prefs?.getString(keyThemeMode);
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final val = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    };
    await _prefs?.setString(keyThemeMode, val);
  }

  // 2. Active Class Preference (e.g. 'P3-A', 'P2-B', 'P1-A')
  String get activeClass => _prefs?.getString(keyActiveClass) ?? 'P3-A';

  Future<void> setActiveClass(String className) async {
    await _prefs?.setString(keyActiveClass, className);
  }

  // 3. Assessment Timer Mode Preference ('count_up', 'countdown_60', 'no_limit')
  String get timerMode => _prefs?.getString(keyTimerMode) ?? 'count_up';

  Future<void> setTimerMode(String mode) async {
    await _prefs?.setString(keyTimerMode, mode);
  }

  // 4. Preferred Language Preference ('English', 'Kinyarwanda', 'French')
  String get preferredLanguage =>
      _prefs?.getString(keyPreferredLanguage) ?? 'English';

  Future<void> setPreferredLanguage(String language) async {
    await _prefs?.setString(keyPreferredLanguage, language);
  }

  // 5. Sound / Haptic Feedback Preference (true / false)
  bool get hapticFeedback => _prefs?.getBool(keyHapticFeedback) ?? true;

  Future<void> setHapticFeedback(bool enabled) async {
    await _prefs?.setBool(keyHapticFeedback, enabled);
  }
}

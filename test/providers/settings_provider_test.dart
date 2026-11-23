import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_dev_summative_menya/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('settings persist across an app restart', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final first = SettingsProvider(prefs);
    await first.setThemeMode(ThemeMode.dark);
    await first.setNotificationsEnabled(false);
    await first.setRememberedEmail('a@b.com');
    await first.setSelectedClassId('class-1');

    // A new provider on the same prefs simulates relaunching the app.
    final second = SettingsProvider(prefs);
    expect(second.themeMode, ThemeMode.dark);
    expect(second.notificationsEnabled, isFalse);
    expect(second.rememberedEmail, 'a@b.com');
    expect(second.selectedClassId, 'class-1');
  });

  test('defaults are used when nothing is saved', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsProvider(await SharedPreferences.getInstance());

    expect(settings.themeMode, ThemeMode.light);
    expect(settings.notificationsEnabled, isTrue);
    expect(settings.rememberedEmail, isEmpty);
    expect(settings.selectedClassId, isNull);
  });
}

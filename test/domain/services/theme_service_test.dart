import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_qil/domain/services/theme_service.dart';

void main() {
  late ThemeService themeService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    themeService = ThemeService();
    await themeService.initialize();
  });

  test('initialize loads light theme by default', () {
    expect(themeService.themeMode, ThemeMode.light);
    expect(themeService.isDarkMode, isFalse);
  });

  test('setThemeMode persists mode and notifies listeners', () async {
    var notified = false;
    themeService.addListener(() => notified = true);

    await themeService.setThemeMode(ThemeMode.dark);

    expect(themeService.themeMode, ThemeMode.dark);
    expect(themeService.isDarkMode, isTrue);
    expect(notified, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
  });

  test('toggleTheme switches between light and dark', () async {
    await themeService.toggleTheme();
    expect(themeService.isDarkMode, isTrue);

    await themeService.toggleTheme();
    expect(themeService.isDarkMode, isFalse);
  });

  test('lightTheme and darkTheme provide distinct color schemes', () {
    final light = themeService.lightTheme.colorScheme;
    final dark = themeService.darkTheme.colorScheme;

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.primary, isNot(equals(dark.primary)));
  });
}

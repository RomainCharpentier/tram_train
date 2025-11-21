import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_qil/view/theme/app_palette.dart';
// Removed SemanticColors in favor of AppBrandColors
import 'package:train_qil/view/theme/app_brand_colors.dart';

/// Service pour gérer les thèmes de l'application
class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  bool _isDarkMode = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  /// Initialise le service de thème
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
      _isDarkMode = true;
    } else {
      _themeMode = ThemeMode.light; // Default to light theme
      _isDarkMode = false;
    }
    notifyListeners();
  }

  /// Change le mode de thème
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _isDarkMode = mode == ThemeMode.dark;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _isDarkMode ? 'dark' : 'light');

    notifyListeners();
  }

  /// Bascule entre le thème clair et sombre
  Future<void> toggleTheme() async {
    final newMode = _isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Obtient le thème clair personnalisé
  ThemeData get lightTheme {
    final palette = AppPalette.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: palette.primary,
        secondary: palette.secondary,
        surface: palette.surface,
        error: const Color(0xFFE53E3E),
        onSecondary: Colors.white,
        onSurface: palette.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppBrandColors.light(),
        palette,
      ],
    );
  }
  /// Obtient le thème sombre personnalisé
  ThemeData get darkTheme {
    final palette = AppPalette.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: palette.primary,
        secondary: palette.secondary,
        surface: palette.surface,
        error: const Color(0xFFE53E3E),
        onSurface: palette.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppBrandColors.dark(),
        palette,
      ],
    );
  }
}

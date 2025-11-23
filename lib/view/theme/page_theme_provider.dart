import 'package:flutter/material.dart';

class PageThemeColors {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color accent;

  const PageThemeColors({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
  });

  static PageThemeColors forPage(int index, [Brightness? brightness]) {
    final isDark = brightness == Brightness.dark;
    switch (index) {
      case 0:
        return PageThemeColors(
          primary: isDark ? const Color(0xFF7BB3F5) : const Color(0xFF2563EB),
          primaryLight: isDark ? const Color(0xFF9BC5FF) : const Color(0xFF3B82F6),
          primaryDark: isDark ? const Color(0xFF6BA3E8) : const Color(0xFF1D4ED8),
          accent: isDark ? const Color(0xFF9BC5FF) : const Color(0xFF60A5FA),
        );
      case 1: // Traffic Info (Teal)
        return PageThemeColors(
          primary: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
          primaryLight: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF14B8A6),
          primaryDark: isDark ? const Color(0xFF14B8A6) : const Color(0xFF0F766E),
          accent: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF2DD4BF),
        );
      case 2: // Notifications (Orange)
        return PageThemeColors(
          primary: isDark ? const Color(0xFFFFA366) : const Color(0xFFEA580C),
          primaryLight: isDark ? const Color(0xFFFFB88C) : const Color(0xFFF97316),
          primaryDark: isDark ? const Color(0xFFFF8C42) : const Color(0xFFC2410C),
          accent: isDark ? const Color(0xFFFFB88C) : const Color(0xFFFB923C),
        );
      case 3: // Profile (Purple)
        return PageThemeColors(
          primary: isDark ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA),
          primaryLight: isDark ? const Color(0xFFE9D5FF) : const Color(0xFFA855F7),
          primaryDark: isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE),
          accent: isDark ? const Color(0xFFE9D5FF) : const Color(0xFFC084FC),
        );
      default:
        return PageThemeColors(
          primary: isDark ? const Color(0xFF7BB3F5) : const Color(0xFF4A90E2),
          primaryLight: isDark ? const Color(0xFF9BC5FF) : const Color(0xFF5BA0F2),
          primaryDark: isDark ? const Color(0xFF6BA3E8) : const Color(0xFF2E5BBA),
          accent: isDark ? const Color(0xFF9BC5FF) : const Color(0xFF6BB0F2),
        );
    }
  }
}

class PageThemeProvider extends InheritedWidget {
  final PageThemeColors colors;

  const PageThemeProvider({
    super.key,
    required this.colors,
    required super.child,
  });

  static PageThemeColors of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<PageThemeProvider>();
    if (provider != null) return provider.colors;
    final brightness = Theme.of(context).brightness;
    return PageThemeColors.forPage(0, brightness);
  }

  @override
  bool updateShouldNotify(PageThemeProvider oldWidget) {
    return colors.primary != oldWidget.colors.primary;
  }
}


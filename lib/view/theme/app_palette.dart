import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color gradientStart;
  final Color gradientEnd;
  final Color surface;
  final Color card;
  final Color onSurface;
  final Color outline;
  final Color muted;

  const AppPalette({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.gradientStart,
    required this.gradientEnd,
    required this.surface,
    required this.card,
    required this.onSurface,
    required this.outline,
    required this.muted,
  });

  factory AppPalette.light() => const AppPalette(
        primary: Color(0xFF4A90E2),
        secondary: Color(0xFF2E5BBA),
        tertiary: Color(0xFF1E3A8A),
        gradientStart: Color(0xFF4A90E2),
        gradientEnd: Color(0xFF2E5BBA),
        surface: Colors.white,
        card: Colors.white,
        onSurface: Color(0xFF1A202C),
        outline: Color(0xFFE5E7EB),
        muted: Color(0xFF6B7280),
      );

  factory AppPalette.dark() => const AppPalette(
        primary: Color(0xFF5BA0F2),
        secondary: Color(0xFF3B6BB0),
        tertiary: Color(0xFF3B6BB0),
        gradientStart: Color(0xFF5BA0F2),
        gradientEnd: Color(0xFF3B6BB0),
        surface: Color(0xFF1A1A1A),
        card: Color(0xFF2A2A2A),
        onSurface: Colors.white,
        outline: Color(0xFF374151),
        muted: Color(0xFF9CA3AF),
      );

  @override
  AppPalette copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? gradientStart,
    Color? gradientEnd,
    Color? surface,
    Color? card,
    Color? onSurface,
    Color? outline,
    Color? muted,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      onSurface: onSurface ?? this.onSurface,
      outline: outline ?? this.outline,
      muted: muted ?? this.muted,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      tertiary: Color.lerp(tertiary, other.tertiary, t) ?? tertiary,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t) ?? gradientStart,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t) ?? gradientEnd,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      card: Color.lerp(card, other.card, t) ?? card,
      onSurface: Color.lerp(onSurface, other.onSurface, t) ?? onSurface,
      outline: Color.lerp(outline, other.outline, t) ?? outline,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
    );
  }
}

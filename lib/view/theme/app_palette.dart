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
  final Color textPrimary;

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
    required this.textPrimary,
  });

  factory AppPalette.light() => const AppPalette(
        primary: Color(0xFF4A90E2),
        secondary: Color(0xFF2E5BBA),
        tertiary: Color(0xFF1E3A8A),
        gradientStart: Color(0xFF4A90E2),
        gradientEnd: Color(0xFF2E5BBA),
        surface: Color(0xFFF0F2F5),
        card: Colors.white,
        onSurface: Color(0xFF1A202C),
        outline: Color(0xFFD1D5DB),
        muted: Color(0xFF6B7280),
        textPrimary: Color(0xFF1A202C),
      );

  factory AppPalette.dark() => const AppPalette(
        primary: Color(0xFF7BB3F5),
        secondary: Color(0xFF6BA3E8),
        tertiary: Color(0xFF6BA3E8),
        gradientStart: Color(0xFF7BB3F5),
        gradientEnd: Color(0xFF6BA3E8),
        surface: Color(0xFF1A1A1A),
        card: Color(0xFF2A2A2A),
        onSurface: Color(0xFFE5E7EB),
        outline: Color(0xFF4B5563),
        muted: Color(0xFF9CA3AF),
        textPrimary: Color(0xFFE5E7EB),
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
    Color? textPrimary,
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
      textPrimary: textPrimary ?? this.textPrimary,
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
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
    );
  }
}

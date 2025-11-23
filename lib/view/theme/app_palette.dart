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
        primary: Color(0xFF6366F1), // Indigo 500
        secondary: Color(0xFF14B8A6), // Teal 500
        tertiary: Color(0xFF8B5CF6), // Violet 500
        gradientStart: Color(0xFF6366F1),
        gradientEnd: Color(0xFF8B5CF6),
        surface: Color(0xFFF8FAFC), // Slate 50
        card: Colors.white,
        onSurface: Color(0xFF0F172A), // Slate 900
        outline: Color(0xFFE2E8F0), // Slate 200
        muted: Color(0xFF64748B), // Slate 500
        textPrimary: Color(0xFF0F172A),
      );

  factory AppPalette.dark() => const AppPalette(
        primary: Color(0xFF818CF8), // Indigo 400
        secondary: Color(0xFF2DD4BF), // Teal 400
        tertiary: Color(0xFFA78BFA), // Violet 400
        gradientStart: Color(0xFF6366F1),
        gradientEnd: Color(0xFF8B5CF6),
        surface: Color(0xFF0F172A), // Slate 900
        card: Color(0xFF1E293B), // Slate 800
        onSurface: Color(0xFFF1F5F9), // Slate 100
        outline: Color(0xFF334155), // Slate 700
        muted: Color(0xFF94A3B8), // Slate 400
        textPrimary: Color(0xFFF1F5F9),
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

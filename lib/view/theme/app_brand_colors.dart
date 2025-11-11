import 'package:flutter/material.dart';

@immutable
class AppBrandColors extends ThemeExtension<AppBrandColors> {
  final Color primary;
  final Color secondary;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  const AppBrandColors({
    required this.primary,
    required this.secondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  factory AppBrandColors.light() => const AppBrandColors(
        primary: Color(0xFF4A90E2),
        secondary: Color(0xFF2E5BBA),
        success: Color(0xFF22C55E),
        warning: Color(0xFFF59E0B),
        error: Color(0xFFE53E3E),
        info: Color(0xFF4A90E2),
      );

  factory AppBrandColors.dark() => const AppBrandColors(
        primary: Color(0xFF7BB3F5),
        secondary: Color(0xFF6BA3E8),
        success: Color(0xFF4ADE80),
        warning: Color(0xFFFFA366),
        error: Color(0xFFF87171),
        info: Color(0xFF7BB3F5),
      );

  @override
  AppBrandColors copyWith({
    Color? primary,
    Color? secondary,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
  }) {
    return AppBrandColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
    );
  }

  @override
  AppBrandColors lerp(ThemeExtension<AppBrandColors>? other, double t) {
    if (other is! AppBrandColors) return this;
    return AppBrandColors(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      error: Color.lerp(error, other.error, t) ?? error,
      info: Color.lerp(info, other.info, t) ?? info,
    );
  }
}

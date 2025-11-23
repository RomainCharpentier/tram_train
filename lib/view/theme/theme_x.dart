import 'package:flutter/material.dart';
import 'package:train_qil/view/theme/app_palette.dart';
import 'package:train_qil/view/theme/app_brand_colors.dart';

class AppThemeColors {
  final BuildContext context;
  const AppThemeColors(this.context);

  ColorScheme get _cs => Theme.of(context).colorScheme;
  AppBrandColors get _bc => Theme.of(context).extension<AppBrandColors>()!;
  AppPalette get _ap => Theme.of(context).extension<AppPalette>()!;

  Color get primary => _bc.primary;
  Color get tertiary => _ap.tertiary;
  Color get error {
    final color = _bc.error;
    return Theme.of(context).brightness == Brightness.dark
        ? color.withValues(alpha:0.75)
        : color;
  }
  Color get onPrimary => _cs.onPrimary;
  
  Color get textPrimary {
    final color = _ap.onSurface;
    return Theme.of(context).brightness == Brightness.dark
        ? color.withValues(alpha:0.95)
        : color;
  }
  Color get textSecondary {
    final color = _ap.muted;
    return Theme.of(context).brightness == Brightness.dark
        ? color.withValues(alpha:0.80)
        : color;
  }
  Color get textOnPrimary => _cs.onPrimary;
  Color get bgSurface => _ap.surface;
  Color get bgCard => _ap.card;
  Color get border => _ap.outline;
  Color get surface => _ap.surface;
  Color get card => _ap.card;
  Color get onSurface => _ap.onSurface;
  Color get outline {
    final color = _ap.outline;
    return Theme.of(context).brightness == Brightness.dark
        ? color.withValues(alpha:0.60)
        : color;
  }
  Color get muted {
    final color = _ap.muted;
    return Theme.of(context).brightness == Brightness.dark
        ? color.withValues(alpha:0.80)
        : color;
  }

  Color get success {
    final color = _bc.success;
    return Theme.of(context).brightness == Brightness.dark
        ? color.withValues(alpha:0.70)
        : color;
  }
  
  Color get warning => _bc.warning;
  Color get info => _bc.info;
  Color get secondary => _bc.secondary;
  Color _alpha(Color c, double a) => c.withValues(alpha: a);
  Color get errorBg => _alpha(error, 0.08);
  Color get errorBorder => _alpha(error, 0.3);
  Color get successBg => _alpha(success, 0.08);
  Color get successBorder => _alpha(success, 0.3);

  Color get gradientStart => _ap.gradientStart;
  Color get gradientEnd => _ap.gradientEnd;

  BoxDecoration get glass => BoxDecoration(
        color: card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: outline.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  BoxDecoration get glassStrong => BoxDecoration(
        color: card.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: outline.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      );

  BoxDecoration get gradientCard => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientStart.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      );
}

extension AppThemeX on BuildContext {
  AppThemeColors get theme => AppThemeColors(this);
}

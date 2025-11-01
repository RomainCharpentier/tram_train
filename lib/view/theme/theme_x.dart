import 'package:flutter/material.dart';
import 'package:train_qil/view/theme/app_palette.dart';
import 'package:train_qil/view/theme/app_brand_colors.dart';

class AppThemeColors {
  final BuildContext context;
  const AppThemeColors(this.context);

  ColorScheme get _cs => Theme.of(context).colorScheme;
  AppBrandColors get _bc => Theme.of(context).extension<AppBrandColors>()!;
  AppPalette get _ap => Theme.of(context).extension<AppPalette>()!;

  // Couleurs de base (ColorScheme)
  // API simple demandée: primary/secondary/success/warning/error/info
  Color get primary => _bc.primary;
  Color get secondary => _bc.secondary;
  Color get tertiary => _ap.tertiary;
  Color get error => _bc.error;
  Color get onPrimary => _cs.onPrimary;
  // Alias texte/fonds/bordure explicites
  Color get textPrimary => _ap.onSurface;
  Color get textSecondary => _ap.muted;
  Color get textOnPrimary => _cs.onPrimary;
  Color get bgSurface => _ap.surface;
  Color get bgCard => _ap.card;
  Color get border => _ap.outline;
  Color get surface => _ap.surface;
  Color get card => _ap.card;
  Color get onSurface => _ap.onSurface;
  Color get outline => _ap.outline;
  Color get muted => _ap.muted;

  // Couleurs sémantiques
  Color get success => _bc.success;
  Color get warning => _bc.warning;
  Color get info => _bc.info;

  // Aides alpha fréquentes
  Color _alpha(Color c, double a) => c.withValues(alpha: a);
  Color get errorBg => _alpha(error, 0.08);
  Color get errorBorder => _alpha(error, 0.3);
  Color get successBg => _alpha(success, 0.08);
  Color get successBorder => _alpha(success, 0.3);

  // Gradients
  Color get gradientStart => _ap.gradientStart;
  Color get gradientEnd => _ap.gradientEnd;
}

extension AppThemeX on BuildContext {
  AppThemeColors get theme => AppThemeColors(this);
}



import 'package:flutter/material.dart';

/// Design tokens pour un système de design cohérent et professionnel
class DesignTokens {
  // Espacements (8px grid system)
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // Rayons de bordure
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusFull = 999.0;

  // Ombres (système d'élévation)
  static List<BoxShadow> get shadowSM => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMD => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowLG => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get shadowXL => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  // Durées d'animation
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Courbes d'animation
  static const Curve curveEaseIn = Curves.easeIn;
  static const Curve curveEaseOut = Curves.easeOut;
  static const Curve curveEaseInOut = Curves.easeInOut;
  static const Curve curveEaseOutCubic = Curves.easeOutCubic;
  static const Curve curveEaseOutQuart = Curves.easeOutQuart;
  static const Curve curveEaseOutBack = Curves.easeOutBack;

  // Tailles d'icônes
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;

  // Hauteurs de composants
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double cardMinHeight = 80.0;

  // Opacités
  static const double opacityDisabled = 0.38;
  static const double opacityHover = 0.08;
  static const double opacityPressed = 0.12;
  static const double opacityGlass = 0.85;
  static const double opacityGlassStrong = 0.95;
}


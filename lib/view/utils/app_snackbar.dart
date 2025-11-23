import 'package:flutter/material.dart';
import '../theme/theme_x.dart';

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 4),
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? context.theme.primary;
    final finalBgColor = isDark
        ? bgColor.withValues(alpha: 0.75)
        : bgColor;
    final finalTextColor = textColor ??
        (isDark ? Colors.black : Colors.white);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: finalTextColor),
        ),
        backgroundColor: finalBgColor,
        duration: duration,
        behavior: behavior,
      ),
    );
  }

  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      backgroundColor: context.theme.success,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 5),
  }) {
    show(
      context,
      message: message,
      backgroundColor: context.theme.error,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 5),
  }) {
    // Utiliser bleu au lieu d'orange pour éviter le conflit avec les pages orange
    final warningColor = Colors.blue.shade700;
    show(
      context,
      message: message,
      backgroundColor: warningColor,
      textColor: Colors.white, // Texte blanc pour meilleur contraste
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      backgroundColor: context.theme.info,
      duration: duration,
    );
  }
}


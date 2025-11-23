import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Transitions de page personnalisées pour une meilleure UX
class PageTransitions {
  static Route<T> fadeRoute<T extends Object?>(
    Widget page, {
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? DesignTokens.animationNormal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: DesignTokens.curveEaseOut,
          ),
          child: child,
        );
      },
    );
  }

  static Route<T> slideRoute<T extends Object?>(
    Widget page, {
    Duration? duration,
    Offset begin = const Offset(0.0, 0.1),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? DesignTokens.animationNormal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: DesignTokens.curveEaseOutCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }

  static Route<T> scaleRoute<T extends Object?>(
    Widget page, {
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? DesignTokens.animationNormal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: DesignTokens.curveEaseOutBack,
        );

        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }
}


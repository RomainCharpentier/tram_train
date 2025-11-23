import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/theme_x.dart';
import '../theme/design_tokens.dart';

/// Version améliorée de GlassContainer avec meilleure UX
class EnhancedGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity;
  final Color? color;
  final BoxBorder? border;
  final VoidCallback? onTap;
  final bool interactive;
  final double elevation;

  const EnhancedGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 10.0,
    this.opacity = 0.85,
    this.color,
    this.border,
    this.onTap,
    this.interactive = false,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(DesignTokens.radiusXL);
    final shadows = elevation == 0
        ? DesignTokens.shadowMD
        : elevation == 1
            ? DesignTokens.shadowSM
            : elevation == 2
                ? DesignTokens.shadowMD
                : DesignTokens.shadowLG;

    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(DesignTokens.spaceMD),
            decoration: BoxDecoration(
              color: (color ?? context.theme.card).withValues(alpha: opacity),
              borderRadius: radius,
              border: border ??
                  Border.all(
                    color: context.theme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
              boxShadow: shadows,
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null || interactive) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: context.theme.primary.withValues(alpha: 0.1),
          highlightColor: context.theme.primary.withValues(alpha: 0.05),
          child: container,
        ),
      );
    }

    return container;
  }
}


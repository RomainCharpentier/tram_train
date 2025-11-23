import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/page_theme_provider.dart';
import '../theme/design_tokens.dart';

class SaveButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final bool isLoading;

  const SaveButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final pageColors = PageThemeProvider.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: DesignTokens.animationFast,
      curve: DesignTokens.curveEaseOut,
      child: ElevatedButton(
        onPressed: (enabled && !isLoading) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: pageColors.primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          padding: const EdgeInsets.symmetric(
            vertical: DesignTokens.spaceMD,
            horizontal: DesignTokens.spaceLG,
          ),
          minimumSize: const Size(double.infinity, DesignTokens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
          ),
          elevation: enabled ? 2 : 0,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.black : Colors.white,
                  ),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

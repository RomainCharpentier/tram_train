import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme_x.dart';
import '../theme/design_tokens.dart';
import '../theme/page_theme_provider.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final pageColors = PageThemeProvider.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceXL),
              decoration: BoxDecoration(
                color: pageColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: pageColors.primary.withValues(alpha: 0.6),
              ),
            )
                .animate()
                .scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 300.ms),
            const SizedBox(height: DesignTokens.spaceXL),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.theme.textPrimary,
                letterSpacing: -0.3,
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms)
                .slideY(begin: 0.1, end: 0, duration: 300.ms),
            const SizedBox(height: DesignTokens.spaceSM),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                color: context.theme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 300.ms)
                .slideY(begin: 0.1, end: 0, duration: 300.ms),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.spaceXL),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: pageColors.primary,
                  foregroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spaceLG,
                    vertical: DesignTokens.spaceMD,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 300.ms)
                  .scale(
                    delay: 400.ms,
                    duration: 300.ms,
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/page_theme_provider.dart';
import '../theme/theme_x.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? dateLabel;
  final Widget? trailing;
  final bool showBackButton;
  final VoidCallback? onBack;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.dateLabel,
    this.trailing,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final pageColors = PageThemeProvider.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dateLabel != null) ...[
            Text(
              dateLabel!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.theme.primary,
                letterSpacing: 1.0,
              ),
            ).animate().fadeIn().slideX(begin: -0.1, end: 0),
            const SizedBox(height: 4),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBackButton) ...[
                Container(
                  margin: const EdgeInsets.only(right: 12, top: 4),
                  decoration: BoxDecoration(
                    color: context.theme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.theme.outline.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onBack ?? () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: context.theme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      pageColors.primaryDark,
                      pageColors.primary,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -1.0,
                    ),
                  ),
                ).animate().fadeIn(delay: dateLabel != null ? 100.ms : 0.ms).slideX(begin: -0.1, end: 0),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: context.theme.textSecondary,
              ),
            ).animate().fadeIn(delay: (dateLabel != null ? 200 : 100).ms).slideX(begin: -0.1, end: 0),
          ],
        ],
      ),
    );
  }
}


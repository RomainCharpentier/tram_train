import 'package:flutter/material.dart';
import '../theme/theme_x.dart';
import '../theme/design_tokens.dart';

class SwitchCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceMD),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        border: Border.all(
          color: context.theme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: DesignTokens.shadowSM,
      ),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceMD,
            vertical: DesignTokens.spaceSM,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: context.theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          subtitle: subtitle != null
              ? Padding(
                  padding: const EdgeInsets.only(top: DesignTokens.spaceXS),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      color: context.theme.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                )
              : null,
          value: value,
          onChanged: onChanged,
          activeThumbColor: context.theme.primary,
          activeTrackColor: context.theme.primary.withValues(alpha: 0.5),
          inactiveThumbColor: Colors.grey.shade300,
          inactiveTrackColor: Colors.grey.shade200,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/theme_x.dart';

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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.outline),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha:0.3)
                : Colors.black.withValues(alpha:0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(color: context.theme.textPrimary),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(color: context.theme.textSecondary),
              )
            : null,
        value: value,
        onChanged: onChanged,
        activeThumbColor: context.theme.primary,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/theme_x.dart';

/// Badge indiquant que les données viennent du cache
class CacheIndicator extends StatelessWidget {
  final bool isCached;

  const CacheIndicator({
    super.key,
    required this.isCached,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCached) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.theme.info.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.theme.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cached,
            size: 12,
            color: context.theme.info,
          ),
          const SizedBox(width: 4),
          Text(
            'Cache',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: context.theme.info,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

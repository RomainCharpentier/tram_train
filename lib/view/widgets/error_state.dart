import 'package:flutter/material.dart';
import '../theme/theme_x.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 64, color: context.theme.error.withValues(alpha: 0.8)),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(fontSize: 16, color: context.theme.textPrimary),
              textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.theme.primary,
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ],
      ),
    );
  }
}

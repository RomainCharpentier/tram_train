import 'dart:async';
import '../utils/error_message_mapper.dart';

/// Service pour gérer les retries automatiques
class RetryService {
  /// Exécute une fonction avec retry automatique en cas d'erreur récupérable
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 2),
    bool Function(Object)? shouldRetry,
  }) async {
    int attempts = 0;

    while (attempts < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        // Vérifier si on doit retry
        final canRetry = shouldRetry?.call(e) ?? ErrorMessageMapper.isRetryable(e);

        if (!canRetry || attempts >= maxAttempts) {
          rethrow;
        }

        // Attendre avant de retry
        await Future.delayed(delay * attempts); // Backoff exponentiel
      }
    }

    throw Exception('Max retry attempts reached');
  }
}

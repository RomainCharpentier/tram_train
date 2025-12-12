import 'dart:io';

/// Mappe les erreurs techniques vers des messages user-friendly
class ErrorMessageMapper {
  /// Convertit une erreur en message compréhensible pour l'utilisateur
  static String toUserFriendlyMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    // Erreurs de connexion réseau
    if (error is SocketException || errorString.contains('socketexception')) {
      return 'Pas de connexion internet. Vérifiez votre connexion réseau.';
    }

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Problème de connexion réseau. Vérifiez votre connexion internet.';
    }

    // Erreurs de timeout
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'La requête a pris trop de temps. Réessayez dans quelques instants.';
    }

    // Erreurs HTTP
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Erreur d\'authentification. Vérifiez votre clé API.';
    }

    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Accès refusé. Vérifiez vos permissions.';
    }

    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Ressource introuvable.';
    }

    if (errorString.contains('429') || errorString.contains('too many requests')) {
      return 'Trop de requêtes. Veuillez patienter quelques instants.';
    }

    if (errorString.contains('500') || errorString.contains('internal server error')) {
      return 'Erreur serveur. Réessayez plus tard.';
    }

    if (errorString.contains('502') || errorString.contains('bad gateway')) {
      return 'Service temporairement indisponible. Réessayez dans quelques instants.';
    }

    if (errorString.contains('503') || errorString.contains('service unavailable')) {
      return 'Service temporairement indisponible. Réessayez plus tard.';
    }

    // Erreurs spécifiques SNCF
    if (errorString.contains('sncf') || errorString.contains('api')) {
      if (errorString.contains('erreur api')) {
        final match = RegExp(r'(\d{3})').firstMatch(errorString);
        if (match != null) {
          final statusCode = match.group(1);
          return 'Erreur API SNCF ($statusCode). Réessayez plus tard.';
        }
      }
      return 'Erreur lors de la communication avec l\'API SNCF. Réessayez.';
    }

    // Erreurs de format/données
    if (errorString.contains('format') || errorString.contains('invalid')) {
      return 'Données invalides. Veuillez réessayer.';
    }

    if (errorString.contains('json') || errorString.contains('decode')) {
      return 'Erreur lors du traitement des données. Réessayez.';
    }

    // Erreur générique
    return 'Une erreur est survenue. Réessayez.';
  }

  /// Vérifie si l'erreur est récupérable (peut être réessayée)
  static bool isRetryable(Object error) {
    final errorString = error.toString().toLowerCase();

    // Les erreurs réseau et timeout sont récupérables
    if (error is SocketException ||
        errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return true;
    }

    // Les erreurs 5xx sont généralement récupérables
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return true;
    }

    // Les erreurs 429 (rate limit) sont récupérables après un délai
    if (errorString.contains('429') || errorString.contains('too many requests')) {
      return true;
    }

    return false;
  }
}

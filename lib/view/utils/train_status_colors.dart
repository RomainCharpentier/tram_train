import 'package:flutter/material.dart';
import '../../domain/models/train.dart';

/// Utilitaires pour les couleurs de statut des trains
/// Système de couleurs unifié :
/// - Bleu : train en cours
/// - Noir : conforme (à l'heure)
/// - Orange : retard
/// - Rouge : annulé
/// - Gris : pas encore d'info
class TrainStatusColors {
  // Couleur bleue pour les trains en cours
  static const Color inProgressColor = Color(0xFF3B82F6);
  
  // Couleurs pour les statuts
  static const Color onTimeColor = Colors.black;
  static const Color delayedColor = Colors.orange;
  static const Color cancelledColor = Colors.red;
  static const Color earlyColor = Colors.black; // En avance = conforme = noir
  static const Color unknownColor = Colors.grey;

  /// Retourne la couleur appropriée selon le statut du train
  /// Si le train est en cours, retourne toujours le bleu
  static Color getStatusColor(
    TrainStatus status, {
    bool isInProgress = false,
  }) {
    if (isInProgress) {
      return inProgressColor;
    }

    switch (status) {
      case TrainStatus.onTime:
        return onTimeColor;
      case TrainStatus.delayed:
        return delayedColor;
      case TrainStatus.cancelled:
        return cancelledColor;
      case TrainStatus.early:
        return earlyColor;
      case TrainStatus.unknown:
        return unknownColor;
    }
  }

  /// Vérifie si un train est en cours
  static bool isTrainInProgress(Train train) {
    final now = DateTime.now();
    return train.departureTime.isBefore(now) &&
        train.arrivalTime != null &&
        train.arrivalTime!.isAfter(now);
  }

  /// Retourne l'icône appropriée selon le statut
  static IconData getStatusIcon(TrainStatus status, {bool isInProgress = false}) {
    if (isInProgress) {
      return Icons.train;
    }

    switch (status) {
      case TrainStatus.onTime:
        return Icons.check_circle;
      case TrainStatus.delayed:
        return Icons.schedule;
      case TrainStatus.cancelled:
        return Icons.cancel;
      case TrainStatus.early:
        return Icons.schedule;
      case TrainStatus.unknown:
        return Icons.help_outline;
    }
  }
}


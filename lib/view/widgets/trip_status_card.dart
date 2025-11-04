import 'package:flutter/material.dart';
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/train.dart';
import '../theme/theme_x.dart';
import 'train_status_indicator.dart';

/// Widget réutilisable pour afficher une carte de statut de trajet
/// Utilisé dans TripCard et TripProgressPage pour avoir un affichage identique
class TripStatusCard extends StatelessWidget {
  final domain.Trip trip;
  final Train? train;
  final VoidCallback? onTap;

  const TripStatusCard({
    super.key,
    required this.trip,
    this.train,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Indicateur de statut
              TrainStatusIndicator(train: train),
              const SizedBox(width: 16),
              // Informations du trajet
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (train != null) ...[
                      Text(
                        'Prochain départ: ${train!.departureTimeFormatted}',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.theme.textSecondary,
                        ),
                      ),
                    ] else ...[
                      Text(
                        '${trip.daysName} à ${trip.timeFormatted}',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.theme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


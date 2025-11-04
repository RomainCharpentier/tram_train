import 'package:flutter/material.dart';
import '../theme/theme_x.dart';
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/train.dart';
import 'train_status_indicator.dart';

class TripCard extends StatelessWidget {
  final domain.Trip trip;
  final Train? nextTrain;
  final void Function(String action, domain.Trip trip) onAction;
  final VoidCallback? onTap;

  const TripCard(
      {super.key, required this.trip, this.nextTrain, required this.onAction, this.onTap});

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
              // Contenu réutilisable (sans le Card extérieur)
              Expanded(
                child: Row(
                  children: [
                    TrainStatusIndicator(train: nextTrain),
                    const SizedBox(width: 16),
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
                          if (nextTrain != null) ...[
                            Text(
                              'Prochain départ: ${nextTrain!.departureTimeFormatted}',
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
              // Menu
              PopupMenuButton<String>(
                onSelected: (value) => onAction(value, trip),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Modifier'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Dupliquer'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: ListTile(
                      leading: Icon(Icons.play_arrow),
                      title: Text('Activer/Désactiver'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

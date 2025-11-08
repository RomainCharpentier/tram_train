import 'package:flutter/material.dart';
import '../theme/theme_x.dart';
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/train.dart';
import '../utils/train_status_colors.dart';
import 'train_status_indicator.dart';

class TripCard extends StatelessWidget {
  final domain.Trip trip;
  final Train? nextTrain;
  final void Function(String action, domain.Trip trip) onAction;
  final VoidCallback? onTap;

  const TripCard({
    super.key,
    required this.trip,
    this.nextTrain,
    required this.onAction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final presentation = nextTrain != null ? TrainStatusColors.buildPresentation(nextTrain!) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
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
                          if (presentation != null) ...[
                            Text(
                              presentation.primaryText,
                              style: TextStyle(
                                fontSize: 14,
                                color: presentation.primaryColor,
                                fontWeight: presentation.state == TrainJourneyState.cancelled
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            if (presentation.scheduleText != null &&
                                presentation.scheduleColor != null &&
                                presentation.scheduleIcon != null) ...[
                              const SizedBox(height: 4),
                              _buildScheduleBadge(presentation),
                            ],
                            if (nextTrain != null &&
                                nextTrain!.departurePlatform != null &&
                                nextTrain!.departurePlatform!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Voie: ${nextTrain!.departurePlatform}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.theme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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

  Widget _buildScheduleBadge(TrainStatusPresentation presentation) {
    final color = presentation.scheduleColor!;
    final icon = presentation.scheduleIcon!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            presentation.scheduleText!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

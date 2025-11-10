import 'package:flutter/material.dart';
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/train.dart';
import '../theme/theme_x.dart';
import '../utils/train_status_colors.dart';
import 'train_status_indicator.dart';

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
    final presentation =
        train != null ? TrainStatusColors.buildPresentation(train!) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              TrainStatusIndicator(train: train),
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
                          fontWeight:
                              presentation.state == TrainJourneyState.cancelled
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

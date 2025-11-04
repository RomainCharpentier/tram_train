import 'package:flutter/material.dart';
import '../theme/theme_x.dart';
import '../../domain/models/train.dart';
import '../utils/train_status_colors.dart';

class TrainCard extends StatelessWidget {
  final Train train;
  final VoidCallback? onTap;
  final bool showDelayBadge;
  final bool showAdditionalInfo;

  const TrainCard({
    super.key,
    required this.train,
    this.onTap,
    this.showDelayBadge = true,
    this.showAdditionalInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: TrainStatusColors.getStatusColor(
            train.status,
            isInProgress: TrainStatusColors.isTrainInProgress(train),
          ),
          child: Icon(
            TrainStatusColors.getStatusIcon(
              train.status,
              isInProgress: TrainStatusColors.isTrainInProgress(train),
            ),
            color: Colors.white,
            size: 16,
          ),
        ),
        title: Text(
          '${train.departureTimeFormatted} - ${train.direction}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(train.statusText),
        trailing: _buildTrailing(context),
        onTap: onTap,
      ),
    );
  }

  Widget? _buildTrailing(BuildContext context) {
    if (showDelayBadge && train.isDelayed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: TrainStatusColors.delayedColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '+${train.delayMinutes}min',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    if (showAdditionalInfo && train.additionalInfo.isNotEmpty) {
      return Text(
        train.additionalInfo.first,
        style: TextStyle(fontSize: 10, color: context.theme.muted),
      );
    }
    return null;
  }
}

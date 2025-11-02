import 'package:flutter/material.dart';
import '../theme/theme_x.dart';
import '../../domain/models/train.dart';

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
          backgroundColor: _getStatusColor(context, train.status),
          child: Icon(
            _getStatusIcon(train.status),
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
          color: context.theme.warning,
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

  Color _getStatusColor(BuildContext context, TrainStatus status) {
    switch (status) {
      case TrainStatus.onTime:
        return context.theme.success;
      case TrainStatus.delayed:
        return context.theme.warning;
      case TrainStatus.early:
        return context.theme.primary;
      case TrainStatus.cancelled:
        return context.theme.error;
      case TrainStatus.unknown:
        return context.theme.outline;
    }
  }

  IconData _getStatusIcon(TrainStatus status) {
    switch (status) {
      case TrainStatus.onTime:
        return Icons.check_circle;
      case TrainStatus.delayed:
        return Icons.schedule;
      case TrainStatus.early:
        return Icons.schedule;
      case TrainStatus.cancelled:
        return Icons.cancel;
      case TrainStatus.unknown:
        return Icons.help;
    }
  }
}

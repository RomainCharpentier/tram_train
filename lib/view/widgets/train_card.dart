import 'package:flutter/material.dart';
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
          backgroundColor: _getStatusColor(train.status),
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
        trailing: _buildTrailing(),
        onTap: onTap,
      ),
    );
  }

  Widget? _buildTrailing() {
    if (showDelayBadge && train.isDelayed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange,
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
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      );
    }
    return null;
  }

  Color _getStatusColor(TrainStatus status) {
    switch (status) {
      case TrainStatus.onTime:
        return Colors.green;
      case TrainStatus.delayed:
        return Colors.orange;
      case TrainStatus.early:
        return Colors.blue;
      case TrainStatus.cancelled:
        return Colors.red;
      case TrainStatus.unknown:
        return Colors.grey;
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



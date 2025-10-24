import 'package:flutter/material.dart';
import '../../domain/models/train.dart';

class TrainCard extends StatelessWidget {
  final Train train;

  const TrainCard({
    super.key,
    required this.train,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    train.direction,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(context),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(train.departureTime),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (train.baseDepartureTime != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(base: ${_formatTime(train.baseDepartureTime!)})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            if (train.additionalInfo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: train.additionalInfo.map((info) => Chip(
                  label: Text(info),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color chipColor;
    switch (train.status) {
      case TrainStatus.onTime:
        chipColor = Colors.green;
        break;
      case TrainStatus.delayed:
        chipColor = Colors.orange;
        break;
      case TrainStatus.early:
        chipColor = Colors.blue;
        break;
      case TrainStatus.cancelled:
        chipColor = Colors.red;
        break;
      case TrainStatus.unknown:
        chipColor = Colors.grey;
        break;
    }

    return Chip(
      label: Text(
        train.statusText,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

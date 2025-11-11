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
    final presentation = TrainStatusColors.buildPresentation(train, context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.outline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: presentation.primaryColor,
          child: Icon(
            presentation.primaryIcon,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
            size: 16,
          ),
        ),
        title: Text(
          '${train.departureTimeFormatted} - ${train.direction}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.theme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              presentation.primaryText,
              style: TextStyle(
                fontSize: 12,
                color: presentation.primaryColor,
                fontWeight: presentation.state == TrainJourneyState.cancelled
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            if (presentation.scheduleText != null &&
                presentation.scheduleColor != null) ...[
              const SizedBox(height: 2),
              Text(
                presentation.scheduleText!,
                style: TextStyle(
                  fontSize: 12,
                  color: presentation.scheduleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        textColor: context.theme.textPrimary,
        iconColor: context.theme.textPrimary,
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
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
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

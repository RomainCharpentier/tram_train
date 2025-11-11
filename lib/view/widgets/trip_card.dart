import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final bool showStatusIndicator;
  final bool showActions;

  const TripCard({
    super.key,
    required this.trip,
    this.nextTrain,
    required this.onAction,
    this.onTap,
    this.showStatusIndicator = true,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final presentation =
        nextTrain != null ? TrainStatusColors.buildPresentation(nextTrain!, context) : null;

    final trailingWidgets = <Widget>[];
    if (nextTrain?.externalUrl != null && nextTrain!.externalUrl!.isNotEmpty) {
      trailingWidgets.add(
        IconButton(
          tooltip: 'Ouvrir sur SNCF.com',
          icon: Icon(Icons.open_in_new, color: context.theme.textPrimary),
          onPressed: () => _openExternalUrl(context, nextTrain!.externalUrl!),
        ),
      );
    }
    if (showActions) {
      trailingWidgets.add(
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: context.theme.textPrimary),
          onSelected: (value) => onAction(value, trip),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, color: context.theme.textPrimary),
                title: Text('Modifier', style: TextStyle(color: context.theme.textPrimary)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                leading: Icon(Icons.copy, color: context.theme.textPrimary),
                title: Text('Dupliquer', style: TextStyle(color: context.theme.textPrimary)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                leading: Icon(Icons.play_arrow, color: context.theme.textPrimary),
                title:
                    Text('Activer/Désactiver', style: TextStyle(color: context.theme.textPrimary)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: context.theme.error),
                title: Text(
                  'Supprimer',
                  style: TextStyle(color: context.theme.error),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showStatusIndicator) ...[
                  TrainStatusIndicator(train: nextTrain),
                  const SizedBox(width: 16),
                ] else ...[
                  Icon(Icons.calendar_today, color: context.theme.textSecondary, size: 24),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        trip.description.isNotEmpty ? trip.description : 'Trajet sans description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                if (trailingWidgets.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ...trailingWidgets,
                ],
              ],
            ),
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
        color: color.withOpacity(0.12),
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

  Future<void> _openExternalUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien inexploitable')),
      );
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir le lien SNCF")),
      );
    }
  }
}

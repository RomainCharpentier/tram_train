import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/theme_x.dart';
import '../theme/design_tokens.dart';
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/train.dart';
import '../utils/train_status_colors.dart';
import 'train_status_indicator.dart';
import 'glass_container.dart';

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

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceMD),
      opacity: 0.9,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
          splashColor: context.theme.primary.withValues(alpha: 0.1),
          highlightColor: context.theme.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showStatusIndicator) ...[
                      TrainStatusIndicator(train: nextTrain),
                      const SizedBox(width: DesignTokens.spaceMD),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(DesignTokens.spaceMD),
                        decoration: BoxDecoration(
                          color: context.theme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                          border: Border.all(
                            color: context.theme.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.train_outlined,
                          color: context.theme.primary,
                          size: DesignTokens.iconMD,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spaceMD),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  trip.description.isNotEmpty
                                      ? trip.description
                                      : 'Trajet sans description',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: context.theme.textPrimary,
                                    letterSpacing: -0.3,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (showActions) _buildActionsMenu(context),
                            ],
                          ),
                          const SizedBox(height: DesignTokens.spaceXS),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: DesignTokens.iconXS,
                                color: context.theme.textSecondary.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: DesignTokens.spaceXS),
                              Text(
                                '${trip.daysName} • ${trip.timeFormatted}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.theme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (presentation != null) ...[
                  const SizedBox(height: DesignTokens.spaceMD),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceMD,
                      vertical: DesignTokens.spaceSM,
                    ),
                    decoration: BoxDecoration(
                      color: presentation.scheduleColor?.withValues(alpha: 0.08) ??
                          context.theme.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                      border: Border.all(
                        color: (presentation.scheduleColor ?? context.theme.outline)
                            .withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (presentation.scheduleIcon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(DesignTokens.spaceXS),
                            decoration: BoxDecoration(
                              color: (presentation.scheduleColor ?? context.theme.primary)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                            ),
                            child: Icon(
                              presentation.scheduleIcon,
                              size: DesignTokens.iconSM,
                              color: presentation.scheduleColor ?? context.theme.primary,
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spaceSM),
                        ],
                        Expanded(
                          child: Text(
                            presentation.scheduleText ?? 'En attente...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: presentation.scheduleColor ?? context.theme.textPrimary,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        if (nextTrain?.externalUrl != null)
                          IconButton(
                            icon: Icon(Icons.open_in_new, size: 18, color: context.theme.primary),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () => _openExternalUrl(context, nextTrain!.externalUrl!),
                            tooltip: 'Voir sur SNCF',
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate()
        .fadeIn(duration: DesignTokens.animationNormal.inMilliseconds.ms)
        .slideY(
          begin: 0.08,
          end: 0,
          curve: DesignTokens.curveEaseOutCubic,
          duration: DesignTokens.animationNormal.inMilliseconds.ms,
        )
        .scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          curve: DesignTokens.curveEaseOutCubic,
          duration: DesignTokens.animationNormal.inMilliseconds.ms,
        );
  }

  Widget _buildActionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: context.theme.textSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) => onAction(value, trip),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: _buildMenuItem(context, Icons.edit_outlined, 'Modifier'),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: _buildMenuItem(context, Icons.copy_outlined, 'Dupliquer'),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: _buildMenuItem(
            context,
            trip.isActive ? Icons.notifications_off_outlined : Icons.notifications_active_outlined,
            trip.isActive ? 'Désactiver' : 'Activer',
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: _buildMenuItem(context, Icons.delete_outline, 'Supprimer', isDestructive: true),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String label,
      {bool isDestructive = false}) {
    final color = isDestructive ? context.theme.error : context.theme.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Future<void> _openExternalUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

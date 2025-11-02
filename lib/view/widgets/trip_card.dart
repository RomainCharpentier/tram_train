import 'package:flutter/material.dart';
import '../theme/theme_x.dart';
import '../../domain/models/trip.dart' as domain;

class TripCard extends StatelessWidget {
  final domain.Trip trip;
  final void Function(String action, domain.Trip trip) onAction;
  final VoidCallback? onTap;

  const TripCard(
      {super.key, required this.trip, required this.onAction, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              trip.isActive ? context.theme.success : context.theme.outline,
          child: Icon(
            trip.isActive ? Icons.check_circle : Icons.pause_circle,
            color: Colors.white,
          ),
        ),
        title: Text(
          trip.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${trip.daysName} à ${trip.timeFormatted}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  trip.isActive ? Icons.play_circle : Icons.pause_circle,
                  size: 16,
                  color: trip.isActive
                      ? context.theme.success
                      : context.theme.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  trip.isActive ? 'Actif' : 'Inactif',
                  style: TextStyle(
                    color: trip.isActive
                        ? context.theme.success
                        : context.theme.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  trip.notificationsEnabled
                      ? Icons.notifications
                      : Icons.notifications_off,
                  size: 16,
                  color: trip.notificationsEnabled
                      ? context.theme.warning
                      : context.theme.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  trip.notificationsEnabled
                      ? 'Notifications'
                      : 'Pas de notifications',
                  style: TextStyle(
                    color: trip.notificationsEnabled
                        ? context.theme.warning
                        : context.theme.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (trip.isForToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.theme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Aujourd\'hui',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
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
        onTap: onTap,
      ),
    );
  }
}

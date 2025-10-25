import '../models/station.dart';
import '../models/alert.dart';
import 'notification_pause_service.dart';

/// Service pour la gestion des alertes et notifications
class AlertService {
  final AlertStorage _storage;
  final NotificationGateway _notificationGateway;
  final NotificationPauseService _pauseService;

  const AlertService({
    required AlertStorage storage,
    required NotificationGateway notificationGateway,
    required NotificationPauseService pauseService,
  }) : _storage = storage, _notificationGateway = notificationGateway, _pauseService = pauseService;

  /// Crée une nouvelle alerte
  Future<Alert> createAlert({
    required String title,
    required String message,
    required AlertType type,
    required Station station,
    required String lineId,
    required DateTime startTime,
    required DateTime endTime,
    required bool isActive,
  }) async {
    final alert = Alert(
      id: Alert.generateId(),
      title: title,
      message: message,
      type: type,
      station: station,
      lineId: lineId,
      startTime: startTime,
      endTime: endTime,
      isActive: isActive,
      createdAt: DateTime.now(),
    );

    await _storage.saveAlert(alert);
    return alert;
  }

  /// Récupère toutes les alertes
  Future<List<Alert>> getAllAlerts() async {
    return await _storage.getAllAlerts();
  }

  /// Récupère les alertes actives
  Future<List<Alert>> getActiveAlerts() async {
    final alerts = await _storage.getAllAlerts();
    return alerts.where((alert) => alert.isActive).toList();
  }

  /// Récupère les alertes pour une gare
  Future<List<Alert>> getAlertsForStation(Station station) async {
    final alerts = await _storage.getAllAlerts();
    return alerts.where((alert) => alert.station.id == station.id).toList();
  }

  /// Récupère les alertes pour une ligne
  Future<List<Alert>> getAlertsForLine(String lineId) async {
    final alerts = await _storage.getAllAlerts();
    return alerts.where((alert) => alert.lineId == lineId).toList();
  }

  /// Met à jour une alerte
  Future<void> updateAlert(Alert alert) async {
    await _storage.saveAlert(alert);
  }

  /// Supprime une alerte
  Future<void> deleteAlert(String alertId) async {
    await _storage.deleteAlert(alertId);
  }

  /// Active/désactive une alerte
  Future<void> toggleAlert(String alertId, bool isActive) async {
    final alerts = await _storage.getAllAlerts();
    final alert = alerts.firstWhere((a) => a.id == alertId);
    final updatedAlert = Alert(
      id: alert.id,
      title: alert.title,
      message: alert.message,
      type: alert.type,
      station: alert.station,
      lineId: alert.lineId,
      startTime: alert.startTime,
      endTime: alert.endTime,
      isActive: isActive,
      createdAt: alert.createdAt,
    );
    await _storage.saveAlert(updatedAlert);
  }

  /// Envoie une notification push
  Future<void> sendPushNotification(Alert alert) async {
    await _notificationGateway.sendPushNotification(
      title: alert.title,
      body: alert.message,
      data: {
        'alert_id': alert.id,
        'station_id': alert.station.id,
        'line_id': alert.lineId,
        'type': alert.type.toString(),
      },
    );
  }

  /// Envoie une notification locale
  Future<void> sendLocalNotification(Alert alert) async {
    // Vérifier si les notifications sont en pause
    final arePaused = await _pauseService.areNotificationsPaused();
    if (arePaused) {
      return; // Ne pas envoyer de notification si en pause
    }

    await _notificationGateway.sendLocalNotification(
      title: alert.title,
      body: alert.message,
      payload: alert.id,
    );
  }

  /// Vérifie et envoie les alertes programmées
  Future<void> checkScheduledAlerts() async {
    // Vérifier si les notifications sont en pause
    final arePaused = await _pauseService.areNotificationsPaused();
    if (arePaused) {
      return; // Ne pas vérifier les alertes si en pause
    }

    final alerts = await getActiveAlerts();
    final now = DateTime.now();

    for (final alert in alerts) {
      if (now.isAfter(alert.startTime) && now.isBefore(alert.endTime)) {
        await sendLocalNotification(alert);
      }
    }
  }
}

/// Interface pour le stockage des alertes
abstract class AlertStorage {
  Future<void> saveAlert(Alert alert);
  Future<List<Alert>> getAllAlerts();
  Future<void> deleteAlert(String alertId);
}

/// Interface pour les notifications
abstract class NotificationGateway {
  Future<void> sendPushNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  });
  
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    required String payload,
  });
}

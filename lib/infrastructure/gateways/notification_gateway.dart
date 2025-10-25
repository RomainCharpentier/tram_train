import '../../domain/services/alert_service.dart';

/// Gateway simple pour les notifications (version de base)
class SimpleNotificationGateway implements NotificationGateway {
  @override
  Future<void> sendPushNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    // Pour l'instant, on affiche juste dans la console
    // TODO: Implémenter les vraies notifications push
    print('🔔 Push Notification: $title - $body');
    print('📊 Data: $data');
  }

  @override
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    // Pour l'instant, on affiche juste dans la console
    // TODO: Implémenter les vraies notifications locales
    print('🔔 Local Notification: $title - $body');
    print('📊 Payload: $payload');
  }
}

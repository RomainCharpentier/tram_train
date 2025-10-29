import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/trip.dart';

/// Service pour gérer les notifications locales
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialise le service de notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Configuration des notifications locales
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Demander les permissions
    await _requestPermissions();

    _isInitialized = true;
  }

  /// Demande les permissions de notification
  Future<bool> _requestPermissions() async {
    final localPermission = await Permission.notification.request();
    return localPermission.isGranted;
  }

  /// Affiche une notification locale
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'train_qil_channel',
      'Train\'Qil Notifications',
      channelDescription: 'Notifications pour les trajets de train',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Gère le tap sur une notification
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapée: ${response.payload}');
    // TODO: Navigation vers la page appropriée
  }

  /// Envoie une notification de retard
  Future<void> notifyDelay(Trip trip, int delayMinutes) async {
    await _showLocalNotification(
      title: 'Retard signalé',
      body:
          'Votre train ${trip.departureStation.name} → ${trip.arrivalStation.name} a ${delayMinutes}min de retard',
      payload: 'trip_delay:${trip.id}',
    );
  }

  /// Envoie une notification d'annulation
  Future<void> notifyCancellation(Trip trip) async {
    await _showLocalNotification(
      title: 'Train annulé',
      body:
          'Votre train ${trip.departureStation.name} → ${trip.arrivalStation.name} a été annulé',
      payload: 'trip_cancelled:${trip.id}',
    );
  }

  /// Envoie une notification de rappel
  Future<void> notifyReminder(Trip trip, int minutesBefore) async {
    await _showLocalNotification(
      title: 'Rappel de départ',
      body:
          'Votre train ${trip.departureStation.name} → ${trip.arrivalStation.name} part dans ${minutesBefore}min',
      payload: 'trip_reminder:${trip.id}',
    );
  }
}

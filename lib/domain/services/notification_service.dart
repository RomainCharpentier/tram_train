import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;
import '../models/trip.dart';

/// Service pour gérer les notifications locales
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      await _initializeWeb();
    } else {
      await _initializeMobile();
    }

    await _requestPermissions();
    _isInitialized = true;
  }

  Future<void> _initializeWeb() async {
    // Pour le web, on utilise directement l'API native du navigateur
    // Pas besoin d'initialiser flutter_local_notifications
  }

  Future<void> _initializeMobile() async {
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
  }

  Future<bool> _requestPermissions() async {
    if (kIsWeb) {
      return await _requestWebPermission();
    }
    final localPermission = await Permission.notification.request();
    return localPermission.isGranted;
  }

  Future<void> _showWebNotification(String title, String body) async {
    if (!html.Notification.supported) {
      throw Exception('Notifications non supportées par le navigateur');
    }

    final permissionStatus = html.Notification.permission;

    if (permissionStatus == 'granted') {
      html.Notification(title, body: body);
      return;
    }

    if (permissionStatus == 'default') {
      final result = await html.Notification.requestPermission();
      if (result == 'granted') {
        html.Notification(title, body: body);
        return;
      }
      throw Exception('Permissions de notification refusées: $result');
    }

    throw Exception('Permissions de notification refusées: $permissionStatus');
  }

  Future<bool> _requestWebPermission() async {
    if (!html.Notification.supported) {
      return false;
    }

    final permissionStatus = html.Notification.permission;

    if (permissionStatus == 'granted') {
      return true;
    }

    if (permissionStatus == 'default') {
      final result = await html.Notification.requestPermission();
      return result == 'granted';
    }

    return false;
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (kIsWeb) {
      await _showWebNotification(title, body);
    } else {
      await _showMobileNotification(title, body, payload);
    }
  }

  Future<void> _showMobileNotification(
      String title, String body, String? payload) async {
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

    final notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await _localNotifications.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapée: ${response.payload}');
  }

  Future<void> notifyDelay(Trip trip, int delayMinutes) async {
    await _showLocalNotification(
      title: 'Retard signalé',
      body:
          'Votre train ${trip.departureStation.name} → ${trip.arrivalStation.name} a ${delayMinutes}min de retard',
      payload: 'trip_delay:${trip.id}',
    );
  }

  Future<void> notifyCancellation(Trip trip) async {
    await _showLocalNotification(
      title: 'Train annulé',
      body:
          'Votre train ${trip.departureStation.name} → ${trip.arrivalStation.name} a été annulé',
      payload: 'trip_cancelled:${trip.id}',
    );
  }

  Future<void> notifyReminder(Trip trip, int minutesBefore) async {
    await _showLocalNotification(
      title: 'Rappel de départ',
      body:
          'Votre train ${trip.departureStation.name} → ${trip.arrivalStation.name} part dans ${minutesBefore}min',
      payload: 'trip_reminder:${trip.id}',
    );
  }
}

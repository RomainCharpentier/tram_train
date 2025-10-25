import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/alert.dart';
import '../../domain/models/station.dart';
import '../../domain/services/alert_service.dart';

/// Gateway pour le stockage local des alertes
class AlertStorageGateway implements AlertStorage {
  static const String _alertsKey = 'alerts';

  @override
  Future<void> saveAlert(Alert alert) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = await getAllAlerts();
    
    // Remplacer l'alerte existante ou ajouter la nouvelle
    final existingIndex = alerts.indexWhere((a) => a.id == alert.id);
    if (existingIndex != -1) {
      alerts[existingIndex] = alert;
    } else {
      alerts.add(alert);
    }
    
    final alertsJson = alerts.map((alert) => _alertToJson(alert)).toList();
    await prefs.setString(_alertsKey, json.encode(alertsJson));
  }

  @override
  Future<List<Alert>> getAllAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final alertsJson = prefs.getString(_alertsKey);
    
    if (alertsJson == null) return [];
    
    final List<dynamic> alertsList = json.decode(alertsJson);
    return alertsList.map((json) => _alertFromJson(json)).toList();
  }

  @override
  Future<void> deleteAlert(String alertId) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = await getAllAlerts();
    
    alerts.removeWhere((alert) => alert.id == alertId);
    
    final alertsJson = alerts.map((alert) => _alertToJson(alert)).toList();
    await prefs.setString(_alertsKey, json.encode(alertsJson));
  }

  /// Convertit une alerte en JSON
  Map<String, dynamic> _alertToJson(Alert alert) {
    return {
      'id': alert.id,
      'title': alert.title,
      'message': alert.message,
      'type': alert.type.toString(),
      'station': {
        'id': alert.station.id,
        'name': alert.station.name,
        'description': alert.station.description,
      },
      'lineId': alert.lineId,
      'startTime': alert.startTime.toIso8601String(),
      'endTime': alert.endTime.toIso8601String(),
      'isActive': alert.isActive,
      'createdAt': alert.createdAt.toIso8601String(),
    };
  }

  /// Convertit un JSON en alerte
  Alert _alertFromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: AlertType.values.firstWhere(
        (type) => type.toString() == json['type'],
        orElse: () => AlertType.information,
      ),
      station: Station(
        id: json['station']['id'] as String,
        name: json['station']['name'] as String,
        description: json['station']['description'] as String,
      ),
      lineId: json['lineId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

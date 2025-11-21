import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/notification_pause.dart';
import '../../domain/services/notification_pause_service.dart';

/// Gateway pour le stockage local des pauses de notifications
class NotificationPauseStorageGateway implements NotificationPauseStorage {
  static const String _pausesKey = 'notification_pauses';

  @override
  Future<void> saveNotificationPause(NotificationPause pause) async {
    final prefs = await SharedPreferences.getInstance();
    final pauses = await getAllNotificationPauses();

    // Remplacer la pause existante ou ajouter la nouvelle
    final existingIndex = pauses.indexWhere((p) => p.id == pause.id);
    if (existingIndex != -1) {
      pauses[existingIndex] = pause;
    } else {
      pauses.add(pause);
    }

    final pausesJson = pauses.map((pause) => _pauseToJson(pause)).toList();
    await prefs.setString(_pausesKey, json.encode(pausesJson));
  }

  @override
  Future<List<NotificationPause>> getAllNotificationPauses() async {
    final prefs = await SharedPreferences.getInstance();
    final pausesJson = prefs.getString(_pausesKey);

    if (pausesJson == null) return [];

    try {
      final List<dynamic> pausesList = json.decode(pausesJson);
      final List<NotificationPause> validPauses = [];

      for (final pauseData in pausesList) {
        try {
          validPauses.add(_pauseFromJson(pauseData as Map<String, dynamic>));
        } on Object catch (e) {
          debugPrint("Erreur lors du décodage d'une pause: $e");
        }
      }

      if (validPauses.length != pausesList.length && validPauses.isNotEmpty) {
        final validPausesJson =
            validPauses.map((pause) => _pauseToJson(pause)).toList();
        await prefs.setString(_pausesKey, json.encode(validPausesJson));
      }

      return validPauses;
    } on Object catch (e) {
      debugPrint('Erreur lors de la lecture des pauses: $e');
      return [];
    }
  }

  @override
  Future<void> deleteNotificationPause(String pauseId) async {
    final prefs = await SharedPreferences.getInstance();
    final pauses = await getAllNotificationPauses();

    pauses.removeWhere((pause) => pause.id == pauseId);

    final pausesJson = pauses.map((pause) => _pauseToJson(pause)).toList();
    await prefs.setString(_pausesKey, json.encode(pausesJson));
  }

  /// Convertit une pause en JSON
  Map<String, dynamic> _pauseToJson(NotificationPause pause) {
    return {
      'id': pause.id,
      'name': pause.name,
      'startDate': pause.startDate.toIso8601String(),
      'endDate': pause.endDate.toIso8601String(),
      'description': pause.description,
      'isActive': pause.isActive,
      'createdAt': pause.createdAt.toIso8601String(),
    };
  }

  /// Convertit un JSON en pause
  NotificationPause _pauseFromJson(Map<String, dynamic> json) {
    return NotificationPause(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

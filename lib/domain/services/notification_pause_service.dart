import '../models/notification_pause.dart';

/// Service pour la gestion des pauses de notifications
class NotificationPauseService {
  final NotificationPauseStorage _storage;

  const NotificationPauseService({
    required NotificationPauseStorage storage,
  }) : _storage = storage;

  /// Crée une nouvelle pause de notifications
  Future<NotificationPause> createNotificationPause({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
  }) async {
    final pause = NotificationPause(
      id: NotificationPause.generateId(),
      name: name,
      startDate: startDate,
      endDate: endDate,
      description: description,
      isActive: true,
      createdAt: DateTime.now(),
    );

    await _storage.saveNotificationPause(pause);
    return pause;
  }

  /// Récupère toutes les pauses de notifications
  Future<List<NotificationPause>> getAllNotificationPauses() async {
    return await _storage.getAllNotificationPauses();
  }

  /// Alias pour getAllNotificationPauses
  Future<List<NotificationPause>> getAllPauses() async {
    return await getAllNotificationPauses();
  }

  /// Récupère les pauses de notifications actives
  Future<List<NotificationPause>> getActiveNotificationPauses() async {
    final pauses = await _storage.getAllNotificationPauses();
    final now = DateTime.now();
    
    return pauses.where((pause) => 
      now.isAfter(pause.startDate) && now.isBefore(pause.endDate)
    ).toList();
  }

  /// Vérifie si les notifications sont actuellement en pause
  Future<bool> areNotificationsPaused() async {
    final activePauses = await getActiveNotificationPauses();
    return activePauses.isNotEmpty;
  }

  /// Met à jour une pause de notifications
  Future<void> updateNotificationPause(NotificationPause pause) async {
    await _storage.saveNotificationPause(pause);
  }

  /// Alias pour updateNotificationPause
  Future<void> updatePause(NotificationPause pause) async {
    await updateNotificationPause(pause);
  }

  /// Supprime une pause de notifications
  Future<void> deleteNotificationPause(String pauseId) async {
    await _storage.deleteNotificationPause(pauseId);
  }

  /// Alias pour deleteNotificationPause
  Future<void> deletePause(String pauseId) async {
    await deleteNotificationPause(pauseId);
  }

  /// Crée une pause de notifications
  Future<void> createPause(NotificationPause pause) async {
    await _storage.saveNotificationPause(pause);
  }

  /// Récupère les pauses de notifications futures
  Future<List<NotificationPause>> getUpcomingNotificationPauses() async {
    final pauses = await _storage.getAllNotificationPauses();
    final now = DateTime.now();
    
    return pauses.where((pause) => 
      pause.startDate.isAfter(now)
    ).toList();
  }

  /// Récupère les pauses de notifications passées
  Future<List<NotificationPause>> getPastNotificationPauses() async {
    final pauses = await _storage.getAllNotificationPauses();
    final now = DateTime.now();
    
    return pauses.where((pause) => 
      pause.endDate.isBefore(now)
    ).toList();
  }
}

/// Interface pour le stockage des pauses de notifications
abstract class NotificationPauseStorage {
  Future<void> saveNotificationPause(NotificationPause pause);
  Future<List<NotificationPause>> getAllNotificationPauses();
  Future<void> deleteNotificationPause(String pauseId);
}

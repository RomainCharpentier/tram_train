import 'package:flutter/foundation.dart';

/// Modèle représentant une pause de notifications
@immutable
class NotificationPause {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  const NotificationPause({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.description,
    required this.isActive,
    required this.createdAt,
  });

  /// Génère un ID unique pour une pause de notifications
  static String generateId() {
    return 'pause_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Vérifie si la pause de notifications est actuellement active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Vérifie si la pause de notifications est future
  bool get isFuture {
    return DateTime.now().isBefore(startDate);
  }

  /// Vérifie si la pause de notifications est passée
  bool get isPast {
    return DateTime.now().isAfter(endDate);
  }

  /// Calcule la durée de la pause de notifications en jours
  int get durationInDays {
    return endDate.difference(startDate).inDays;
  }

  /// Crée une copie de la pause de notifications avec des valeurs modifiées
  NotificationPause copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return NotificationPause(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationPause && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NotificationPause(id: $id, name: $name, startDate: $startDate, endDate: $endDate, isActive: $isActive)';
  }
}

import 'station.dart';

/// Modèle représentant une alerte
class Alert {
  final String id;
  final String title;
  final String message;
  final AlertType type;
  final Station station;
  final String lineId;
  final DateTime startTime;
  final DateTime endTime;
  final bool isActive;
  final DateTime createdAt;

  const Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.station,
    required this.lineId,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.createdAt,
  });

  /// Génère un ID unique pour une alerte
  static String generateId() {
    return 'alert_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Crée une copie de l'alerte avec des valeurs modifiées
  Alert copyWith({
    String? id,
    String? title,
    String? message,
    AlertType? type,
    Station? station,
    String? lineId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Alert(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      station: station ?? this.station,
      lineId: lineId ?? this.lineId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Alert && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Alert(id: $id, title: $title, type: $type, station: ${station.name}, isActive: $isActive)';
  }
}

/// Types d'alertes disponibles
enum AlertType {
  delay('Retard'),
  cancellation('Suppression'),
  disruption('Perturbation'),
  scheduleChange('Changement d\'horaire'),
  maintenance('Maintenance'),
  information('Information');

  const AlertType(this.displayName);
  final String displayName;

  @override
  String toString() => displayName;
}

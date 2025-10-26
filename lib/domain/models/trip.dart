import 'station.dart';

/// Modèle représentant un trajet enregistré
class Trip {
  final String id;
  final Station departureStation;
  final Station arrivalStation;
  final List<DayOfWeek> days; // Changé pour supporter plusieurs jours
  final TimeOfDay time;
  final bool isActive;
  final bool notificationsEnabled;
  final DateTime createdAt;

  const Trip({
    required this.id,
    required this.departureStation,
    required this.arrivalStation,
    required this.days,
    required this.time,
    this.isActive = true,
    this.notificationsEnabled = true,
    required this.createdAt,
  });

  /// Génère un ID unique pour un trajet
  static String generateId() {
    return 'trip_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Vérifie si le trajet est pour aujourd'hui
  bool get isForToday {
    final today = DateTime.now().weekday;
    return days.any((day) => day.index + 1 == today);
  }

  /// Vérifie si le trajet est actif aujourd'hui
  bool get isActiveToday {
    return isActive && isForToday;
  }

  /// Retourne les noms des jours en français
  String get daysName {
    if (days.isEmpty) return 'Aucun jour';
    if (days.length == 1) return days.first.displayName;
    if (days.length == 7) return 'Tous les jours';
    return days.map((d) => d.displayName).join(', ');
  }

  /// Retourne l'heure formatée
  String get timeFormatted {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Retourne la description du trajet
  String get description {
    return '${departureStation.name} → ${arrivalStation.name}';
  }

  /// Crée une copie du trajet avec des valeurs modifiées
  Trip copyWith({
    String? id,
    Station? departureStation,
    Station? arrivalStation,
    List<DayOfWeek>? days,
    TimeOfDay? time,
    bool? isActive,
    bool? notificationsEnabled,
    DateTime? createdAt,
  }) {
    return Trip(
      id: id ?? this.id,
      departureStation: departureStation ?? this.departureStation,
      arrivalStation: arrivalStation ?? this.arrivalStation,
      days: days ?? this.days,
      time: time ?? this.time,
      isActive: isActive ?? this.isActive,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Trip && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Trip(id: $id, ${departureStation.name} → ${arrivalStation.name}, $daysName $timeFormatted, active: $isActive)';
  }
}

/// Jours de la semaine
enum DayOfWeek {
  monday('Lundi'),
  tuesday('Mardi'),
  wednesday('Mercredi'),
  thursday('Jeudi'),
  friday('Vendredi'),
  saturday('Samedi'),
  sunday('Dimanche');

  const DayOfWeek(this.displayName);
  final String displayName;

  /// Retourne le jour de la semaine pour aujourd'hui
  static DayOfWeek get today {
    final today = DateTime.now().weekday;
    return DayOfWeek.values[today - 1];
  }
}

/// Heure de la journée
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({
    required this.hour,
    required this.minute,
  });

  /// Crée une TimeOfDay à partir d'une DateTime
  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(
      hour: dateTime.hour,
      minute: dateTime.minute,
    );
  }

  /// Crée une TimeOfDay à partir d'une chaîne "HH:MM"
  factory TimeOfDay.fromString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  /// Retourne l'heure formatée
  String get formatted {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Retourne une DateTime pour aujourd'hui avec cette heure
  DateTime get todayDateTime {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeOfDay && other.hour == hour && other.minute == minute;
  }

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;

  @override
  String toString() => formatted;
}

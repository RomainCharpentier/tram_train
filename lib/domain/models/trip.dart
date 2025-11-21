import 'package:flutter/foundation.dart';
import 'station.dart';

@immutable
class Trip {
  final String id;
  final Station departureStation;
  final Station arrivalStation;
  final DayOfWeek day;
  final TimeOfDay time;
  final bool isActive;
  final bool notificationsEnabled;
  final DateTime createdAt;

  const Trip({
    required this.id,
    required this.departureStation,
    required this.arrivalStation,
    required this.day,
    required this.time,
    this.isActive = true,
    this.notificationsEnabled = true,
    required this.createdAt,
  });

  static String generateId() {
    return 'trip_${DateTime.now().millisecondsSinceEpoch}';
  }

  bool isForToday([DateTime? now]) {
    final currentTime = now ?? DateTime.now();
    final today = currentTime.weekday;
    return day.index + 1 == today;
  }

  bool isActiveToday([DateTime? now]) {
    return isActive && isForToday(now);
  }

  String get daysName {
    return day.displayName;
  }

  String get timeFormatted {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String get description {
    return '${departureStation.name} → ${arrivalStation.name}';
  }

  Trip copyWith({
    String? id,
    Station? departureStation,
    Station? arrivalStation,
    DayOfWeek? day,
    TimeOfDay? time,
    bool? isActive,
    bool? notificationsEnabled,
    DateTime? createdAt,
  }) {
    return Trip(
      id: id ?? this.id,
      departureStation: departureStation ?? this.departureStation,
      arrivalStation: arrivalStation ?? this.arrivalStation,
      day: day ?? this.day,
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

  static DayOfWeek get today {
    final today = DateTime.now().weekday;
    return DayOfWeek.values[today - 1];
  }
}

@immutable
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({
    required this.hour,
    required this.minute,
  });

  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(
      hour: dateTime.hour,
      minute: dateTime.minute,
    );
  }

  factory TimeOfDay.fromString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String get formatted {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

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

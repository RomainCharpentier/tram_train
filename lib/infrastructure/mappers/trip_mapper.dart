import '../../domain/models/trip.dart';
import '../../domain/models/station.dart';

/// Mapper pour convertir les trajets vers/depuis JSON
class TripMapper {
  /// Convertit un trajet vers JSON
  Map<String, dynamic> toJson(Trip trip) {
    return {
      'id': trip.id,
      'departureStationId': trip.departureStation.id,
      'departureStationName': trip.departureStation.name,
      'arrivalStationId': trip.arrivalStation.id,
      'arrivalStationName': trip.arrivalStation.name,
      'days': trip.days.map((d) => d.name).toList(),
      'timeHour': trip.time.hour,
      'timeMinute': trip.time.minute,
      'isActive': trip.isActive,
      'notificationsEnabled': trip.notificationsEnabled,
      'createdAt': trip.createdAt.toIso8601String(),
    };
  }

  /// Convertit JSON vers un trajet
  Trip fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      departureStation: Station(
        id: json['departureStationId'] as String,
        name: json['departureStationName'] as String,
      ),
      arrivalStation: Station(
        id: json['arrivalStationId'] as String,
        name: json['arrivalStationName'] as String,
      ),
      days: (json['days'] as List<dynamic>?)
              ?.map((d) => DayOfWeek.values.firstWhere(
                    (day) => day.name == d,
                    orElse: () => DayOfWeek.monday,
                  ))
              .toList() ??
          [DayOfWeek.monday],
      time: TimeOfDay(
        hour: json['timeHour'] as int,
        minute: json['timeMinute'] as int,
      ),
      isActive: json['isActive'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

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
      'day': trip.day.name,
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
      day: json['day'] != null
          ? DayOfWeek.values.firstWhere(
              (d) => d.name == json['day'] as String,
              orElse: () => DayOfWeek.monday,
            )
          : (json['days'] as List<dynamic>?)?.isNotEmpty == true
              ? DayOfWeek.values.firstWhere(
                  (d) => d.name == (json['days'] as List<dynamic>).first,
                  orElse: () => DayOfWeek.monday,
                )
              : DayOfWeek.monday,
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
